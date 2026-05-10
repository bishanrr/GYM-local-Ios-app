import Foundation

enum FitnessGoal: String, Codable, CaseIterable, Identifiable, Hashable {
    case fatLoss = "Fat Loss"
    case muscleGain = "Muscle Gain"
    case athleticBody = "Athletic Body"
    case strength = "Strength"
    case athleticPerformance = "Athletic Performance"
    case endurance = "Endurance"
    case generalFitness = "General Fitness"

    var id: String { rawValue }
}

enum ExperienceLevel: String, Codable, CaseIterable, Identifiable, Hashable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var id: String { rawValue }
}

enum WorkoutDurationPreference: Int, Codable, CaseIterable, Identifiable, Hashable {
    case thirty = 30
    case fortyFive = 45
    case sixty = 60
    case ninety = 90

    var id: Int { rawValue }
    var label: String { "\(rawValue) min" }
}

enum EquipmentType: String, Codable, CaseIterable, Identifiable, Hashable {
    case bodyweight = "Bodyweight"
    case dumbbells = "Dumbbells"
    case barbells = "Barbells"
    case machines = "Machines"
    case resistanceBands = "Resistance Bands"
    case fullGym = "Full Gym"

    var id: String { rawValue }
}

enum MuscleGroup: String, Codable, CaseIterable, Identifiable, Hashable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case core = "Core"
    case quads = "Quads"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    case calves = "Calves"
    case fullBody = "Full Body"

    var id: String { rawValue }
}

enum WorkoutSplit: String, Codable, CaseIterable, Identifiable, Hashable {
    case fullBody = "Full Body"
    case pushPullLegs = "Push Pull Legs"
    case upperLower = "Upper Lower"
    case broSplit = "Bro Split"
    case custom = "Custom"

    var id: String { rawValue }
}

enum CardioPreference: String, Codable, CaseIterable, Identifiable, Hashable {
    case none = "Minimal"
    case lowImpact = "Low Impact"
    case intervals = "Intervals"
    case endurance = "Endurance"
    case mixed = "Mixed"

    var id: String { rawValue }
}

enum TrainingStyle: String, Codable, CaseIterable, Identifiable, Hashable {
    case strength = "Strength"
    case hypertrophy = "Hypertrophy"
    case hiit = "HIIT"
    case functional = "Functional"
    case mixed = "Mixed"

    var id: String { rawValue }
}

enum DifficultyLevel: String, Codable, CaseIterable, Identifiable, Hashable {
    case easy = "Easy"
    case moderate = "Moderate"
    case hard = "Hard"
    case elite = "Elite"

    var id: String { rawValue }
}

enum ExercisePhase: String, Codable, CaseIterable, Identifiable, Hashable {
    case warmUp = "Warm Up"
    case main = "Workout"
    case stretching = "Stretching"

    var id: String { rawValue }
}

enum PlanGenerationSource: String, Codable, Hashable {
    case localRules = "Local Rules"
    case remoteAI = "Remote AI"
}

enum UnitsPreference: String, Codable, CaseIterable, Identifiable, Hashable {
    case imperial = "Imperial"
    case metric = "Metric"

    var id: String { rawValue }
    var weightUnit: String { self == .imperial ? "lb" : "kg" }
}

struct UserProfile: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var goal: FitnessGoal
    var experienceLevel: ExperienceLevel
    var workoutDaysPerWeek: Int
    var durationPreference: WorkoutDurationPreference
    var equipment: [EquipmentType]
    var targetMuscles: [MuscleGroup]
    var injuriesOrLimitations: String
    var preferredSplit: WorkoutSplit
    var cardioPreference: CardioPreference
    var trainingStyle: TrainingStyle
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String = "Athlete",
        goal: FitnessGoal,
        experienceLevel: ExperienceLevel,
        workoutDaysPerWeek: Int,
        durationPreference: WorkoutDurationPreference,
        equipment: [EquipmentType],
        targetMuscles: [MuscleGroup],
        injuriesOrLimitations: String,
        preferredSplit: WorkoutSplit,
        cardioPreference: CardioPreference,
        trainingStyle: TrainingStyle,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.goal = goal
        self.experienceLevel = experienceLevel
        self.workoutDaysPerWeek = workoutDaysPerWeek
        self.durationPreference = durationPreference
        self.equipment = equipment
        self.targetMuscles = targetMuscles
        self.injuriesOrLimitations = injuriesOrLimitations
        self.preferredSplit = preferredSplit
        self.cardioPreference = cardioPreference
        self.trainingStyle = trainingStyle
        self.createdAt = createdAt
    }
}

struct RepRange: Codable, Equatable, Hashable {
    var lowerBound: Int
    var upperBound: Int

    var label: String {
        "\(upperBound)"
    }
}

struct Exercise: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var primaryMuscles: [MuscleGroup]
    var secondaryMuscles: [MuscleGroup]
    var instructions: [String]
    var tips: [String]
    var safetyNotes: [String]
    var sets: Int
    var targetReps: RepRange
    var suggestedWeight: Double?
    var restDuration: TimeInterval
    var workDuration: TimeInterval
    var equipment: [EquipmentType]
    var difficulty: DifficultyLevel
    var phase: ExercisePhase

    init(
        id: UUID = UUID(),
        name: String,
        primaryMuscles: [MuscleGroup],
        secondaryMuscles: [MuscleGroup] = [],
        instructions: [String],
        tips: [String],
        safetyNotes: [String],
        sets: Int,
        targetReps: RepRange,
        suggestedWeight: Double? = nil,
        restDuration: TimeInterval,
        workDuration: TimeInterval,
        equipment: [EquipmentType],
        difficulty: DifficultyLevel,
        phase: ExercisePhase = .main
    ) {
        self.id = id
        self.name = name
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.instructions = instructions
        self.tips = tips
        self.safetyNotes = safetyNotes
        self.sets = sets
        self.targetReps = targetReps
        self.suggestedWeight = suggestedWeight
        self.restDuration = restDuration
        self.workDuration = workDuration
        self.equipment = equipment
        self.difficulty = difficulty
        self.phase = phase
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case primaryMuscles
        case secondaryMuscles
        case instructions
        case tips
        case safetyNotes
        case sets
        case targetReps
        case suggestedWeight
        case restDuration
        case workDuration
        case equipment
        case difficulty
        case phase
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        primaryMuscles = try container.decode([MuscleGroup].self, forKey: .primaryMuscles)
        secondaryMuscles = try container.decode([MuscleGroup].self, forKey: .secondaryMuscles)
        instructions = try container.decode([String].self, forKey: .instructions)
        tips = try container.decode([String].self, forKey: .tips)
        safetyNotes = try container.decode([String].self, forKey: .safetyNotes)
        sets = try container.decode(Int.self, forKey: .sets)
        targetReps = try container.decode(RepRange.self, forKey: .targetReps)
        suggestedWeight = try container.decodeIfPresent(Double.self, forKey: .suggestedWeight)
        restDuration = try container.decode(TimeInterval.self, forKey: .restDuration)
        workDuration = try container.decode(TimeInterval.self, forKey: .workDuration)
        equipment = try container.decode([EquipmentType].self, forKey: .equipment)
        difficulty = try container.decode(DifficultyLevel.self, forKey: .difficulty)
        phase = try container.decodeIfPresent(ExercisePhase.self, forKey: .phase) ?? .main
    }
}

struct WorkoutDay: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var weekNumber: Int
    var dayIndex: Int
    var title: String
    var estimatedDurationMinutes: Int
    var exercises: [Exercise]
    var muscleFocus: [MuscleGroup]
    var difficulty: DifficultyLevel

    init(
        id: UUID = UUID(),
        weekNumber: Int,
        dayIndex: Int,
        title: String,
        estimatedDurationMinutes: Int,
        exercises: [Exercise],
        muscleFocus: [MuscleGroup],
        difficulty: DifficultyLevel
    ) {
        self.id = id
        self.weekNumber = weekNumber
        self.dayIndex = dayIndex
        self.title = title
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.exercises = exercises
        self.muscleFocus = muscleFocus
        self.difficulty = difficulty
    }

    var warmUpExercises: [Exercise] {
        exercises.filter { $0.phase == .warmUp }
    }

    var mainExercises: [Exercise] {
        exercises.filter { $0.phase == .main }
    }

    var stretchingExercises: [Exercise] {
        exercises.filter { $0.phase == .stretching }
    }
}

struct WorkoutWeek: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var weekNumber: Int
    var startDate: Date
    var days: [WorkoutDay]

    init(id: UUID = UUID(), weekNumber: Int, startDate: Date, days: [WorkoutDay]) {
        self.id = id
        self.weekNumber = weekNumber
        self.startDate = startDate
        self.days = days
    }
}

struct WorkoutPlan: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var userProfileID: UUID
    var title: String
    var summary: String
    var generatedAt: Date
    var source: PlanGenerationSource
    var weeks: [WorkoutWeek]

    init(
        id: UUID = UUID(),
        userProfileID: UUID,
        title: String,
        summary: String,
        generatedAt: Date = Date(),
        source: PlanGenerationSource,
        weeks: [WorkoutWeek]
    ) {
        self.id = id
        self.userProfileID = userProfileID
        self.title = title
        self.summary = summary
        self.generatedAt = generatedAt
        self.source = source
        self.weeks = weeks
    }

    var currentWeek: WorkoutWeek? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sortedWeeks = weeks.sorted { $0.weekNumber < $1.weekNumber }

        if let activeWeek = sortedWeeks.first(where: { week in
            let startDate = calendar.startOfDay(for: week.startDate)
            let endDate = calendar.date(byAdding: .day, value: 7, to: startDate) ?? startDate
            return today >= startDate && today < endDate
        }) {
            return activeWeek
        }

        return sortedWeeks.first { today < calendar.startOfDay(for: $0.startDate) } ?? sortedWeeks.last
    }
}
