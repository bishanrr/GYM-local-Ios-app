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
        suggestedWeekdayState?.workout
            ?? activeWeek?.days.first { !isWorkoutCompleted($0) }
            ?? activeWeek?.days.first
    }

    var weeklyProgress: Double {
        guard let week = activeWeek, !week.days.isEmpty else { return 0 }
        let completed = weeklyDayStates.filter { $0.status == .completed }.count
        return Double(completed) / Double(week.days.count)
    }

    var completedWorkoutCountThisWeek: Int {
        weeklyDayStates.filter { $0.status == .completed }.count
    }

    var weeklyDayStates: [WeekdayWorkoutState] {
        guard let week = activeWeek else { return [] }

        let calendar = Calendar.current
        let weekStart = calendar.startOfDay(for: week.startDate)
        let workoutsByIndex = Dictionary(uniqueKeysWithValues: week.days.map { ($0.dayIndex, $0) })

        return (1...7).map { weekdayIndex in
            let date = calendar.date(byAdding: .day, value: weekdayIndex - 1, to: weekStart) ?? weekStart
            let deadline = calendar.date(byAdding: .day, value: 7, to: date) ?? date
            let workout = workoutsByIndex[weekdayIndex]
            return WeekdayWorkoutState(
                weekdayIndex: weekdayIndex,
                label: Self.weekdayLabel(for: date),
                date: date,
                deadline: deadline,
                workout: workout,
                status: status(for: workout, scheduledDate: date, deadline: deadline)
            )
        }
    }

    var suggestedWeekdayState: WeekdayWorkoutState? {
        let states = weeklyDayStates
        let calendar = Calendar.current

        if let today = states.first(where: { calendar.isDateInToday($0.date) && $0.workout != nil }) {
            return today
        }

        return states.first { $0.status == .available || $0.status == .incomplete }
            ?? states.first { $0.workout != nil }
            ?? states.first
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

    func isWorkoutIncomplete(_ day: WorkoutDay) -> Bool {
        guard !isWorkoutCompleted(day) else { return false }
        return snapshot.workoutHistory.contains {
            $0.workoutDayID == day.id && !$0.wasCompleted
        }
    }

    func canStartWorkout(_ state: WeekdayWorkoutState) -> Bool {
        guard state.workout != nil else { return false }
        return state.status != .completed && state.status != .missed
    }

    func savedProgress(for day: WorkoutDay) -> SavedWorkoutProgress? {
        snapshot.savedWorkoutProgress.first { $0.workoutDayID == day.id }
    }

    func hasSavedProgress(for day: WorkoutDay) -> Bool {
        savedProgress(for: day) != nil
    }

    func saveWorkoutProgress(_ progress: SavedWorkoutProgress) {
        snapshot.savedWorkoutProgress.removeAll { $0.workoutDayID == progress.workoutDayID }
        snapshot.savedWorkoutProgress.append(progress)
        persist()
    }

    func clearSavedProgress(for day: WorkoutDay) {
        snapshot.savedWorkoutProgress.removeAll { $0.workoutDayID == day.id }
        persist()
    }

    func addExtraExercise(_ exercise: Exercise, to day: WorkoutDay) {
        guard var plan = snapshot.activePlan else { return }

        for weekIndex in plan.weeks.indices {
            guard let dayIndex = plan.weeks[weekIndex].days.firstIndex(where: { $0.id == day.id }) else {
                continue
            }

            var updatedDay = plan.weeks[weekIndex].days[dayIndex]
            guard !updatedDay.exercises.contains(where: { $0.name == exercise.name }) else { return }

            if let stretchingIndex = updatedDay.exercises.firstIndex(where: { $0.phase == .stretching }) {
                updatedDay.exercises.insert(exercise, at: stretchingIndex)
            } else {
                updatedDay.exercises.append(exercise)
            }

            updatedDay.estimatedDurationMinutes += max(1, Int(exercise.workDuration / 60))
            plan.weeks[weekIndex].days[dayIndex] = updatedDay
            snapshot.activePlan = plan
            persist()
            HapticEngine.notify(.success)
            return
        }
    }

    func completeOnboarding(with profile: UserProfile) async {
        do {
            let plan = try await generator.generatePlan(userProfile: profile)
            snapshot.userProfile = profile
            snapshot.activePlan = plan
            snapshot.savedWorkoutProgress = []
            try await store.saveSnapshot(snapshot)
        } catch {
            errorMessage = "Could not generate your plan. Please try again."
        }
    }

    func refreshWorkouts() async {
        guard let profile = snapshot.userProfile else { return }
        do {
            snapshot.activePlan = try await generator.generatePlan(userProfile: profile)
            snapshot.savedWorkoutProgress = []
            try await store.saveSnapshot(snapshot)
            HapticEngine.notify(.success)
        } catch {
            errorMessage = "Refresh failed. Your existing local plan is still safe."
        }
    }

    func recordCompletedWorkout(_ session: WorkoutSession) {
        guard !snapshot.workoutHistory.contains(where: { $0.id == session.id }) else { return }

        snapshot.savedWorkoutProgress.removeAll { $0.workoutDayID == session.workoutDayID }
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
        snapshot.savedWorkoutProgress = []
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

    private func status(for workout: WorkoutDay?, scheduledDate: Date, deadline: Date) -> WeekdayWorkoutStatus {
        guard let workout else { return .rest }

        if isWorkoutCompleted(workout) {
            return .completed
        }

        if Date() >= deadline {
            return .missed
        }

        if hasSavedProgress(for: workout) {
            return .inProgress
        }

        if isWorkoutIncomplete(workout) {
            return .incomplete
        }

        if Date() < scheduledDate {
            return .upcoming
        }

        return .available
    }

    private static func weekdayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "EEEEE"
        return formatter.string(from: date)
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
