import Foundation

protocol WorkoutPlanGenerating {
    func generatePlan(userProfile: UserProfile) async throws -> WorkoutPlan
}

struct WorkoutPlanGeneratorService: WorkoutPlanGenerating {
    func generatePlan(userProfile: UserProfile) async throws -> WorkoutPlan {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let weeks = (0..<2).map { offset in
            let weekStart = calendar.date(byAdding: .day, value: offset * 7, to: startDate) ?? startDate
            return generateWeek(number: offset + 1, startDate: weekStart, userProfile: userProfile)
        }
        let title = "\(userProfile.goal.rawValue) Coach"
        let summary = "Two-week \(userProfile.preferredSplit.rawValue) split tuned for \(userProfile.trainingStyle.rawValue.lowercased()), \(userProfile.durationPreference.label) sessions, and local progressive overload."

        return WorkoutPlan(
            userProfileID: userProfile.id,
            title: title,
            summary: summary,
            source: .localRules,
            weeks: weeks
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

        let mainWork = selected.prefix(targetCount + 1).map { configuredExercise(from: $0, profile: userProfile) }
        return warmUpExercises(for: muscles, profile: userProfile) + mainWork + stretchingExercises(for: muscles, profile: userProfile)
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
        var reps: Int
        var rest: TimeInterval
        var work: TimeInterval

        switch profile.trainingStyle {
        case .strength:
            sets = 4
            reps = 5
            rest = 150
            work = 45
        case .hypertrophy:
            sets = 4
            reps = 10
            rest = 75
            work = 45
        case .hiit:
            sets = 3
            reps = 15
            rest = 35
            work = 40
        case .functional:
            sets = 3
            reps = 12
            rest = 60
            work = 45
        case .mixed:
            sets = 3
            reps = 10
            rest = 70
            work = 45
        }

        switch profile.experienceLevel {
        case .beginner:
            sets = max(2, sets - 1)
            reps = max(5, reps - 1)
            rest += 15
        case .intermediate:
            break
        case .advanced:
            sets += 1
            reps += 1
            rest = max(45, rest - 10)
        }

        if profile.goal == .fatLoss || profile.goal == .endurance || profile.goal == .athleticBody {
            rest = max(30, rest - 10)
        }

        return (sets, exactReps(reps), rest, work)
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

    private func warmUpExercises(for muscles: [MuscleGroup], profile: UserProfile) -> [Exercise] {
        let focus = Set(muscles)
        var warmups: [Exercise] = [
            Exercise(
                name: "Breathing Reset",
                primaryMuscles: [.core],
                secondaryMuscles: [.glutes],
                instructions: ["Stand tall and breathe through the nose.", "Exhale slowly while bracing the ribs down.", "Build light tension before moving."],
                tips: ["Keep this easy and smooth.", "Use the warm-up to scan for restrictions."],
                safetyNotes: ["Skip any movement that reproduces pain."],
                sets: 1,
                targetReps: exactReps(6),
                restDuration: 10,
                workDuration: 35,
                equipment: [.bodyweight],
                difficulty: .easy,
                phase: .warmUp
            )
        ]

        if focus.contains(.chest) || focus.contains(.shoulders) || focus.contains(.back) {
            warmups.append(
                Exercise(
                    name: "Shoulder Activation Flow",
                    primaryMuscles: [.shoulders, .back],
                    secondaryMuscles: [.chest, .core],
                    instructions: ["Circle the shoulders with control.", "Sweep arms overhead without shrugging.", "Finish with slow scapular squeezes."],
                    tips: ["Move through a comfortable range.", "Let the upper back wake up before loading."],
                    safetyNotes: ["Avoid aggressive overhead range if shoulders feel pinchy."],
                    sets: 1,
                    targetReps: exactReps(10),
                    restDuration: 15,
                    workDuration: 45,
                    equipment: [.bodyweight, .resistanceBands],
                    difficulty: .easy,
                    phase: .warmUp
                )
            )
        }

        if focus.contains(.quads) || focus.contains(.hamstrings) || focus.contains(.glutes) || focus.contains(.calves) {
            warmups.append(
                Exercise(
                    name: "Hip + Squat Primer",
                    primaryMuscles: [.glutes, .quads],
                    secondaryMuscles: [.hamstrings, .core],
                    instructions: ["Hinge at the hips for three slow reps.", "Drop into an easy squat and open the hips.", "Stand tall and squeeze the glutes."],
                    tips: ["Keep feet rooted.", "Use this to find your working stance."],
                    safetyNotes: ["Shorten the squat if knees or hips feel irritated."],
                    sets: 1,
                    targetReps: exactReps(8),
                    restDuration: 15,
                    workDuration: 45,
                    equipment: [.bodyweight],
                    difficulty: .easy,
                    phase: .warmUp
                )
            )
        }

        return Array(warmups.prefix(profile.durationPreference == .thirty ? 2 : 3))
    }

    private func stretchingExercises(for muscles: [MuscleGroup], profile: UserProfile) -> [Exercise] {
        let focus = Set(muscles)
        var stretches: [Exercise] = []

        if focus.contains(.chest) || focus.contains(.shoulders) {
            stretches.append(
                Exercise(
                    name: "Chest + Shoulder Stretch",
                    primaryMuscles: [.chest, .shoulders],
                    secondaryMuscles: [.biceps],
                    instructions: ["Set the forearm against a wall or rack.", "Turn gently away until the chest opens.", "Hold with slow breathing."],
                    tips: ["Keep the shoulder low.", "Ease in instead of forcing range."],
                    safetyNotes: ["Back off if the stretch turns sharp or nervy."],
                    sets: 1,
                    targetReps: exactReps(1),
                    restDuration: 10,
                    workDuration: 45,
                    equipment: [.bodyweight, .fullGym],
                    difficulty: .easy,
                    phase: .stretching
                )
            )
        }

        if focus.contains(.back) || focus.contains(.core) {
            stretches.append(
                Exercise(
                    name: "Lat + Spine Reset",
                    primaryMuscles: [.back],
                    secondaryMuscles: [.core, .shoulders],
                    instructions: ["Reach both hands forward on a bench or wall.", "Sit the hips back until the lats lengthen.", "Breathe into the side ribs."],
                    tips: ["Keep the neck relaxed.", "Think long, not intense."],
                    safetyNotes: ["Avoid hanging on the shoulders if they feel unstable."],
                    sets: 1,
                    targetReps: exactReps(1),
                    restDuration: 10,
                    workDuration: 45,
                    equipment: [.bodyweight, .fullGym],
                    difficulty: .easy,
                    phase: .stretching
                )
            )
        }

        if focus.contains(.quads) || focus.contains(.hamstrings) || focus.contains(.glutes) || focus.contains(.calves) {
            stretches.append(
                Exercise(
                    name: "Hip Flexor + Hamstring Stretch",
                    primaryMuscles: [.hamstrings, .glutes],
                    secondaryMuscles: [.quads, .calves],
                    instructions: ["Start in a half-kneeling position.", "Shift forward gently, then straighten the front leg.", "Alternate sides with slow breathing."],
                    tips: ["Keep the pelvis tucked slightly.", "Use support for balance."],
                    safetyNotes: ["Pad the knee and avoid forcing end range."],
                    sets: 1,
                    targetReps: exactReps(1),
                    restDuration: 0,
                    workDuration: 55,
                    equipment: [.bodyweight],
                    difficulty: .easy,
                    phase: .stretching
                )
            )
        }

        if stretches.isEmpty {
            stretches.append(
                Exercise(
                    name: "Full Body Downshift",
                    primaryMuscles: [.fullBody],
                    secondaryMuscles: [.core],
                    instructions: ["Stand tall and inhale through the nose.", "Fold forward softly with bent knees.", "Roll up slowly and repeat."],
                    tips: ["End calmer than you started.", "Stay away from painful range."],
                    safetyNotes: ["Move slowly if you feel lightheaded."],
                    sets: 1,
                    targetReps: exactReps(4),
                    restDuration: 0,
                    workDuration: 45,
                    equipment: [.bodyweight],
                    difficulty: .easy,
                    phase: .stretching
                )
            )
        }

        return Array(stretches.prefix(profile.durationPreference == .thirty ? 2 : 3))
    }

    private func exactReps(_ reps: Int) -> RepRange {
        RepRange(lowerBound: reps, upperBound: reps)
    }
}
