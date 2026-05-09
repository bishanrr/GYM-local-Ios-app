import Foundation
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    @Published private(set) var snapshot = AppSnapshot()
    @Published private(set) var isBootstrapping = true
    @Published var errorMessage: String?

    private let store: LocalWorkoutStore
    private let generator: WorkoutPlanGenerating
    private let progressiveOverloadService: ProgressiveOverloadService

    init(
        store: LocalWorkoutStore = LocalWorkoutStore(),
        generator: WorkoutPlanGenerating = WorkoutPlanGeneratorService(),
        progressiveOverloadService: ProgressiveOverloadService = ProgressiveOverloadService()
    ) {
        self.store = store
        self.generator = generator
        self.progressiveOverloadService = progressiveOverloadService

        Task {
            await load()
        }
    }

    var hasCompletedOnboarding: Bool {
        snapshot.userProfile != nil && snapshot.activePlan != nil
    }

    var activeWeek: WorkoutWeek? {
        snapshot.activePlan?.currentWeek
    }

    var todayWorkout: WorkoutDay? {
        guard let week = activeWeek else { return nil }
        return week.days.first { !isWorkoutCompleted($0) } ?? week.days.first
    }

    var weeklyProgress: Double {
        guard let week = activeWeek, !week.days.isEmpty else { return 0 }
        let completed = week.days.filter { isWorkoutCompleted($0) }.count
        return Double(completed) / Double(week.days.count)
    }

    var completedWorkoutCountThisWeek: Int {
        activeWeek?.days.filter { isWorkoutCompleted($0) }.count ?? 0
    }

    var estimatedCaloriesForToday: Int {
        guard let workout = todayWorkout else { return 0 }
        let intensity: Double
        switch workout.difficulty {
        case .easy:
            intensity = 5.0
        case .moderate:
            intensity = 7.0
        case .hard:
            intensity = 9.0
        case .elite:
            intensity = 10.5
        }
        return Int(Double(workout.estimatedDurationMinutes) * intensity)
    }

    var progressMetrics: ProgressMetrics {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let weeklySessions = snapshot.workoutHistory.filter { $0.completedAt >= weekStart && $0.wasCompleted }

        var breakdown: [MuscleGroup: Int] = [:]
        let volume = weeklySessions.reduce(0.0) { partial, session in
            partial + session.completedExercises.reduce(0.0) { exercisePartial, completedExercise in
                completedExercise.primaryMuscles.forEach {
                    breakdown[$0, default: 0] += completedExercise.sets.count
                }
                return exercisePartial + completedExercise.sets.reduce(0.0) { setPartial, set in
                    setPartial + Double(set.completedReps) * max(set.weight ?? 1, 1)
                }
            }
        }

        return ProgressMetrics(
            weeklyVolume: volume,
            completedWorkouts: weeklySessions.count,
            currentStreak: currentStreak(),
            muscleBreakdown: breakdown
        )
    }

    func isWorkoutCompleted(_ day: WorkoutDay) -> Bool {
        snapshot.workoutHistory.contains {
            $0.workoutDayID == day.id && $0.wasCompleted
        }
    }

    func completeOnboarding(with profile: UserProfile) async {
        do {
            let plan = try await generator.generatePlan(userProfile: profile)
            snapshot.userProfile = profile
            snapshot.activePlan = plan
            try await store.saveSnapshot(snapshot)
        } catch {
            errorMessage = "Could not generate your plan. Please try again."
        }
    }

    func refreshWorkouts() async {
        guard let profile = snapshot.userProfile else { return }
        do {
            snapshot.activePlan = try await generator.generatePlan(userProfile: profile)
            try await store.saveSnapshot(snapshot)
            HapticEngine.notify(.success)
        } catch {
            errorMessage = "Refresh failed. Your existing local plan is still safe."
        }
    }

    func recordCompletedWorkout(_ session: WorkoutSession) {
        guard !snapshot.workoutHistory.contains(where: { $0.id == session.id }) else { return }
        guard !session.completedExercises.isEmpty else { return }

        snapshot.workoutHistory.append(session)
        updatePersonalRecords(from: session)
        generateNextWeekIfReady()
        persist()
    }

    func setDarkMode(_ enabled: Bool) {
        snapshot.settings.darkMode = enabled
        persist()
    }

    func setNotifications(_ enabled: Bool) {
        snapshot.settings.notificationsEnabled = enabled
        persist()
    }

    func setUnits(_ units: UnitsPreference) {
        snapshot.settings.units = units
        persist()
    }

    func resetOnboarding() {
        snapshot.userProfile = nil
        snapshot.activePlan = nil
        persist()
    }

    private func load() async {
        do {
            snapshot = try await store.loadSnapshot()
        } catch {
            snapshot = AppSnapshot()
            errorMessage = "Local data could not be loaded, so a fresh offline profile is ready."
        }
        isBootstrapping = false
    }

    private func persist() {
        let snapshot = snapshot
        Task {
            try? await store.saveSnapshot(snapshot)
        }
    }

    private func generateNextWeekIfReady() {
        guard var plan = snapshot.activePlan,
              let profile = snapshot.userProfile,
              let currentWeek = plan.currentWeek else { return }

        let completedDayIDs = Set(
            snapshot.workoutHistory
                .filter { $0.weekNumber == currentWeek.weekNumber && $0.wasCompleted }
                .map(\.workoutDayID)
        )

        let weekIsComplete = currentWeek.days.allSatisfy { completedDayIDs.contains($0.id) }
        guard weekIsComplete else { return }

        let nextWeek = progressiveOverloadService.generateNextWeek(
            from: currentWeek,
            history: snapshot.workoutHistory,
            profile: profile
        )

        guard !plan.weeks.contains(where: { $0.weekNumber == nextWeek.weekNumber }) else { return }
        plan.weeks.append(nextWeek)
        snapshot.activePlan = plan
    }

    private func updatePersonalRecords(from session: WorkoutSession) {
        for exercise in session.completedExercises {
            for set in exercise.sets where set.wasSuccessful {
                let value = set.weight ?? Double(set.completedReps)
                let unit = set.weight == nil ? "reps" : snapshot.settings.units.weightUnit

                if let index = snapshot.personalRecords.firstIndex(where: {
                    $0.exerciseName == exercise.exerciseName && $0.unit == unit
                }) {
                    if value > snapshot.personalRecords[index].value {
                        snapshot.personalRecords[index] = PersonalRecord(
                            exerciseName: exercise.exerciseName,
                            value: value,
                            unit: unit,
                            achievedAt: set.completedAt
                        )
                    }
                } else {
                    snapshot.personalRecords.append(
                        PersonalRecord(
                            exerciseName: exercise.exerciseName,
                            value: value,
                            unit: unit,
                            achievedAt: set.completedAt
                        )
                    )
                }
            }
        }
    }

    private func currentStreak() -> Int {
        let calendar = Calendar.current
        let completedDays = Set(
            snapshot.workoutHistory
                .filter(\.wasCompleted)
                .map { calendar.startOfDay(for: $0.completedAt) }
        )

        guard !completedDays.isEmpty else { return 0 }

        var cursor = calendar.startOfDay(for: Date())
        if !completedDays.contains(cursor),
           let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor),
           completedDays.contains(yesterday) {
            cursor = yesterday
        }

        var streak = 0
        while completedDays.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }
}
