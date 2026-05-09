import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var name = ""
    @Published var goal: FitnessGoal = .muscleGain
    @Published var experienceLevel: ExperienceLevel = .intermediate
    @Published var workoutDaysPerWeek = 4
    @Published var durationPreference: WorkoutDurationPreference = .fortyFive
    @Published var equipment: Set<EquipmentType> = [.dumbbells, .bodyweight]
    @Published var targetMuscles: Set<MuscleGroup> = [.fullBody]
    @Published var injuriesOrLimitations = ""
    @Published var preferredSplit: WorkoutSplit = .upperLower
    @Published var cardioPreference: CardioPreference = .mixed
    @Published var trainingStyle: TrainingStyle = .hypertrophy
    @Published var isGenerating = false

    func toggleEquipment(_ item: EquipmentType) {
        if equipment.contains(item) {
            equipment.remove(item)
        } else {
            equipment.insert(item)
        }
        if equipment.isEmpty {
            equipment.insert(.bodyweight)
        }
    }

    func toggleMuscle(_ muscle: MuscleGroup) {
        if muscle == .fullBody {
            targetMuscles = [.fullBody]
            return
        }

        targetMuscles.remove(.fullBody)
        if targetMuscles.contains(muscle) {
            targetMuscles.remove(muscle)
        } else {
            targetMuscles.insert(muscle)
        }

        if targetMuscles.isEmpty {
            targetMuscles.insert(.fullBody)
        }
    }

    func makeProfile() -> UserProfile {
        UserProfile(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Athlete" : name,
            goal: goal,
            experienceLevel: experienceLevel,
            workoutDaysPerWeek: workoutDaysPerWeek,
            durationPreference: durationPreference,
            equipment: Array(equipment).sorted { $0.rawValue < $1.rawValue },
            targetMuscles: Array(targetMuscles).sorted { $0.rawValue < $1.rawValue },
            injuriesOrLimitations: injuriesOrLimitations,
            preferredSplit: preferredSplit,
            cardioPreference: cardioPreference,
            trainingStyle: trainingStyle
        )
    }
}
