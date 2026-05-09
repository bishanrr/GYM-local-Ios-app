import Foundation

struct CompletedSet: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var setNumber: Int
    var targetReps: RepRange
    var completedReps: Int
    var weight: Double?
    var wasSuccessful: Bool
    var completedAt: Date

    init(
        id: UUID = UUID(),
        setNumber: Int,
        targetReps: RepRange,
        completedReps: Int,
        weight: Double?,
        wasSuccessful: Bool,
        completedAt: Date = Date()
    ) {
        self.id = id
        self.setNumber = setNumber
        self.targetReps = targetReps
        self.completedReps = completedReps
        self.weight = weight
        self.wasSuccessful = wasSuccessful
        self.completedAt = completedAt
    }
}

struct CompletedExercise: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var exerciseID: UUID
    var exerciseName: String
    var primaryMuscles: [MuscleGroup]
    var sets: [CompletedSet]

    init(
        id: UUID = UUID(),
        exerciseID: UUID,
        exerciseName: String,
        primaryMuscles: [MuscleGroup],
        sets: [CompletedSet]
    ) {
        self.id = id
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.primaryMuscles = primaryMuscles
        self.sets = sets
    }
}

struct WorkoutSession: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var workoutDayID: UUID
    var weekNumber: Int
    var title: String
    var startedAt: Date
    var completedAt: Date
    var durationSeconds: TimeInterval
    var completedExercises: [CompletedExercise]
    var perceivedEffort: Int?
    var wasCompleted: Bool

    init(
        id: UUID = UUID(),
        workoutDayID: UUID,
        weekNumber: Int,
        title: String,
        startedAt: Date,
        completedAt: Date = Date(),
        durationSeconds: TimeInterval,
        completedExercises: [CompletedExercise],
        perceivedEffort: Int? = nil,
        wasCompleted: Bool
    ) {
        self.id = id
        self.workoutDayID = workoutDayID
        self.weekNumber = weekNumber
        self.title = title
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.durationSeconds = durationSeconds
        self.completedExercises = completedExercises
        self.perceivedEffort = perceivedEffort
        self.wasCompleted = wasCompleted
    }
}

struct ProgressMetrics: Codable, Equatable, Hashable {
    var weeklyVolume: Double
    var completedWorkouts: Int
    var currentStreak: Int
    var muscleBreakdown: [MuscleGroup: Int]
}

struct PersonalRecord: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var exerciseName: String
    var value: Double
    var unit: String
    var achievedAt: Date

    init(
        id: UUID = UUID(),
        exerciseName: String,
        value: Double,
        unit: String,
        achievedAt: Date = Date()
    ) {
        self.id = id
        self.exerciseName = exerciseName
        self.value = value
        self.unit = unit
        self.achievedAt = achievedAt
    }
}

struct AppSettings: Codable, Equatable, Hashable {
    var darkMode: Bool
    var units: UnitsPreference
    var notificationsEnabled: Bool

    static let `default` = AppSettings(
        darkMode: true,
        units: .imperial,
        notificationsEnabled: false
    )
}

struct AppSnapshot: Codable, Equatable {
    var userProfile: UserProfile?
    var activePlan: WorkoutPlan?
    var workoutHistory: [WorkoutSession]
    var personalRecords: [PersonalRecord]
    var settings: AppSettings

    init(
        userProfile: UserProfile? = nil,
        activePlan: WorkoutPlan? = nil,
        workoutHistory: [WorkoutSession] = [],
        personalRecords: [PersonalRecord] = [],
        settings: AppSettings = .default
    ) {
        self.userProfile = userProfile
        self.activePlan = activePlan
        self.workoutHistory = workoutHistory
        self.personalRecords = personalRecords
        self.settings = settings
    }
}
