import Foundation

protocol WorkoutPlanGenerating {
    func generatePlan(userProfile: UserProfile) async throws -> WorkoutPlan
}

struct WorkoutPlanGeneratorService: WorkoutPlanGenerating {
    func generatePlan(userProfile: UserProfile) async throws -> WorkoutPlan {
        let week = generateWeek(number: 1, startDate: Date(), userProfile: userProfile)
        let title = "\(userProfile.goal.rawValue) Coach"
        let summary = "\(userProfile.preferredSplit.rawValue) split tuned for \(userProfile.trainingStyle.rawValue.lowercased()), \(userProfile.durationPreference.label) sessions, and local progressive overload."

        return WorkoutPlan(
            userProfileID: userProfile.id,
            title: title,
            summary: summary,
            source: .localRules,
            weeks: [week]
        )
    }

    private func generateWeek(number: Int, startDate: Date, userProfile: UserProfile) -> WorkoutWeek {
        let focusPlan = focusPlan(for: userProfile)
        let days = focusPlan.enumerated().map { offset, focus in
            let exercises = selectExercises(for: focus.muscles, userProfile: userProfile)
            return WorkoutDay(
                weekNumber: number,
                dayIndex: offset + 1,
                title: focus.title,
                estimatedDurationMinutes: userProfile.durationPreference.rawValue,
                exercises: exercises,
                muscleFocus: focus.muscles,
                difficulty: difficulty(for: userProfile)
            )
        }

        return WorkoutWeek(weekNumber: number, startDate: startDate, days: days)
    }

    private func focusPlan(for profile: UserProfile) -> [(title: String, muscles: [MuscleGroup])] {
        let targetedMuscles = profile.targetMuscles.isEmpty || profile.targetMuscles.contains(.fullBody)
            ? MuscleGroup.allCases.filter { $0 != .fullBody }
            : profile.targetMuscles

        let base: [(String, [MuscleGroup])]
        switch profile.preferredSplit {
        case .fullBody:
            base = [
                ("Full Body Strength", [.chest, .back, .quads, .glutes, .core]),
                ("Full Body Power", [.shoulders, .back, .hamstrings, .glutes, .core]),
                ("Full Body Conditioning", [.chest, .quads, .shoulders, .calves, .core])
            ]
        case .pushPullLegs:
            base = [
                ("Push Precision", [.chest, .shoulders, .triceps]),
                ("Pull Engine", [.back, .biceps, .core]),
                ("Leg Drive", [.quads, .hamstrings, .glutes, .calves]),
                ("Athletic Push Pull", [.chest, .back, .shoulders, .core])
            ]
        case .upperLower:
            base = [
                ("Upper Strength", [.chest, .back, .shoulders, .biceps, .triceps]),
                ("Lower Strength", [.quads, .hamstrings, .glutes, .calves]),
                ("Upper Volume", [.chest, .back, .shoulders, .core]),
                ("Lower Athletic", [.quads, .glutes, .hamstrings, .core])
            ]
        case .broSplit:
            base = [
                ("Chest + Triceps", [.chest, .triceps]),
                ("Back + Biceps", [.back, .biceps]),
                ("Legs", [.quads, .hamstrings, .glutes, .calves]),
                ("Shoulders + Core", [.shoulders, .core]),
                ("Athletic Full Body", [.fullBody, .core])
            ]
        case .custom:
            base = targetedMuscles.map { ("Focused \($0.rawValue)", [$0]) }
        }

        let days = max(1, min(profile.workoutDaysPerWeek, 7))
        var result: [(String, [MuscleGroup])] = []
        for index in 0..<days {
            let item = base[index % base.count]
            let muscles = Array(Set(item.1 + Array(targetedMuscles.prefix(2)))).filter { $0 != .fullBody }
            result.append((item.0, muscles.isEmpty ? [.chest, .back, .quads, .core] : muscles))
        }
        return result
    }

    private func selectExercises(for muscles: [MuscleGroup], userProfile: UserProfile) -> [Exercise] {
        let availableEquipment = Set(userProfile.equipment)
        let usableTemplates = ExerciseDatabase.all.filter { template in
            template.equipment.contains(.bodyweight)
            || template.equipment.contains(.fullGym) && availableEquipment.contains(.fullGym)
            || !availableEquipment.isDisjoint(with: Set(template.equipment))
        }

        let focused = usableTemplates.filter { template in
            !Set(template.primaryMuscles + template.secondaryMuscles).isDisjoint(with: Set(muscles))
        }

        let targetCount: Int
        switch userProfile.durationPreference {
        case .thirty:
            targetCount = 4
        case .fortyFive:
            targetCount = 5
        case .sixty:
            targetCount = 6
        case .ninety:
            targetCount = 8
        }

        var selected = Array(focused.prefix(targetCount))
        if selected.count < targetCount {
            selected += usableTemplates.filter { template in
                !selected.contains { $0.name == template.name }
            }.prefix(targetCount - selected.count)
        }

        if userProfile.cardioPreference != .none,
           let finisher = usableTemplates.first(where: { $0.name == "Mountain Climber" || $0.name == "Battle Rope Intervals" }),
           !selected.contains(where: { $0.name == finisher.name }) {
            selected.append(finisher)
        }

        return selected.prefix(targetCount + 1).map { configuredExercise(from: $0, profile: userProfile) }
    }

    private func configuredExercise(from template: ExerciseTemplate, profile: UserProfile) -> Exercise {
        let prescription = prescription(for: profile)
        let suggestedWeight: Double?
        if template.equipment.contains(.bodyweight) && template.equipment.count == 1 {
            suggestedWeight = nil
        } else {
            suggestedWeight = startingWeight(for: template, profile: profile)
        }

        return Exercise(
            name: template.name,
            primaryMuscles: template.primaryMuscles,
            secondaryMuscles: template.secondaryMuscles,
            instructions: template.instructions,
            tips: template.tips,
            safetyNotes: template.safetyNotes,
            sets: prescription.sets,
            targetReps: prescription.reps,
            suggestedWeight: suggestedWeight,
            restDuration: prescription.rest,
            workDuration: prescription.work,
            equipment: template.equipment,
            difficulty: difficulty(for: profile)
        )
    }

    private func prescription(for profile: UserProfile) -> (sets: Int, reps: RepRange, rest: TimeInterval, work: TimeInterval) {
        var sets: Int
        var reps: RepRange
        var rest: TimeInterval
        var work: TimeInterval

        switch profile.trainingStyle {
        case .strength:
            sets = 4
            reps = RepRange(lowerBound: 3, upperBound: 6)
            rest = 150
            work = 45
        case .hypertrophy:
            sets = 4
            reps = RepRange(lowerBound: 8, upperBound: 12)
            rest = 75
            work = 45
        case .hiit:
            sets = 3
            reps = RepRange(lowerBound: 12, upperBound: 18)
            rest = 35
            work = 40
        case .functional:
            sets = 3
            reps = RepRange(lowerBound: 8, upperBound: 14)
            rest = 60
            work = 45
        case .mixed:
            sets = 3
            reps = RepRange(lowerBound: 8, upperBound: 12)
            rest = 70
            work = 45
        }

        switch profile.experienceLevel {
        case .beginner:
            sets = max(2, sets - 1)
            rest += 15
        case .intermediate:
            break
        case .advanced:
            sets += 1
            rest = max(45, rest - 10)
        }

        if profile.goal == .fatLoss || profile.goal == .endurance {
            rest = max(30, rest - 10)
        }

        return (sets, reps, rest, work)
    }

    private func startingWeight(for template: ExerciseTemplate, profile: UserProfile) -> Double {
        let base: Double
        if template.primaryMuscles.contains(.quads) || template.primaryMuscles.contains(.glutes) || template.primaryMuscles.contains(.hamstrings) {
            base = 45
        } else if template.primaryMuscles.contains(.back) || template.primaryMuscles.contains(.chest) {
            base = 30
        } else {
            base = 15
        }

        switch profile.experienceLevel {
        case .beginner:
            return base
        case .intermediate:
            return base * 1.5
        case .advanced:
            return base * 2.0
        }
    }

    private func difficulty(for profile: UserProfile) -> DifficultyLevel {
        switch profile.experienceLevel {
        case .beginner:
            return .moderate
        case .intermediate:
            return profile.trainingStyle == .hiit ? .hard : .moderate
        case .advanced:
            return .hard
        }
    }
}
