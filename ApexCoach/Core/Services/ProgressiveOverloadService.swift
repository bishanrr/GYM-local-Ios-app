import Foundation

struct ProgressiveOverloadService {
    func generateNextWeek(from previousWeek: WorkoutWeek, history: [WorkoutSession], profile: UserProfile) -> WorkoutWeek {
        let successRate = successRate(for: previousWeek, history: history)
        let nextWeekNumber = previousWeek.weekNumber + 1
        let startDate = Calendar.current.date(byAdding: .day, value: 7, to: previousWeek.startDate) ?? Date()

        let progressedDays = previousWeek.days.map { day in
            WorkoutDay(
                weekNumber: nextWeekNumber,
                dayIndex: day.dayIndex,
                title: day.title,
                estimatedDurationMinutes: day.estimatedDurationMinutes,
                exercises: day.exercises.map {
                    progress($0, weekNumber: nextWeekNumber, successRate: successRate, profile: profile)
                },
                muscleFocus: day.muscleFocus,
                difficulty: day.difficulty
            )
        }

        return WorkoutWeek(weekNumber: nextWeekNumber, startDate: startDate, days: progressedDays)
    }

    private func successRate(for week: WorkoutWeek, history: [WorkoutSession]) -> Double {
        let sessions = history.filter { $0.weekNumber == week.weekNumber && $0.wasCompleted }
        let sets = sessions.flatMap(\.completedExercises).flatMap(\.sets)
        guard !sets.isEmpty else { return 0 }
        let successes = sets.filter(\.wasSuccessful).count
        return Double(successes) / Double(sets.count)
    }

    private func progress(_ exercise: Exercise, weekNumber: Int, successRate: Double, profile: UserProfile) -> Exercise {
        var next = exercise
        next.id = UUID()

        if successRate < 0.70 {
            next.restDuration += 10
            if let weight = next.suggestedWeight {
                next.suggestedWeight = max(0, weight * 0.975)
            }
            return next
        }

        guard successRate >= 0.88 else {
            return next
        }

        let bump: Double
        switch profile.experienceLevel {
        case .beginner:
            bump = 1.015
        case .intermediate:
            bump = 1.025
        case .advanced:
            bump = 1.035
        }

        let progressionLane = weekNumber % 4
        switch progressionLane {
        case 0:
            next.targetReps = RepRange(
                lowerBound: exercise.targetReps.lowerBound,
                upperBound: exercise.targetReps.upperBound + 1
            )
        case 1:
            if let weight = exercise.suggestedWeight {
                next.suggestedWeight = roundedTrainingWeight(weight * bump)
            } else {
                next.targetReps = RepRange(
                    lowerBound: exercise.targetReps.lowerBound + 1,
                    upperBound: exercise.targetReps.upperBound + 1
                )
            }
        case 2:
            next.restDuration = max(minimumRest(for: profile), exercise.restDuration - 5)
        default:
            if profile.experienceLevel != .beginner, exercise.sets < 5 {
                next.sets += 1
            } else {
                next.targetReps = RepRange(
                    lowerBound: exercise.targetReps.lowerBound,
                    upperBound: exercise.targetReps.upperBound + 1
                )
            }
        }

        return next
    }

    private func roundedTrainingWeight(_ value: Double) -> Double {
        (value / 2.5).rounded() * 2.5
    }

    private func minimumRest(for profile: UserProfile) -> TimeInterval {
        switch profile.trainingStyle {
        case .strength:
            return 90
        case .hypertrophy, .mixed:
            return 45
        case .hiit, .functional:
            return 25
        }
    }
}
