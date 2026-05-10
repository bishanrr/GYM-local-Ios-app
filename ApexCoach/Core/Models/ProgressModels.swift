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
    var savedWorkoutProgress: [SavedWorkoutProgress]
    var settings: AppSettings

    init(
        userProfile: UserProfile? = nil,
        activePlan: WorkoutPlan? = nil,
        workoutHistory: [WorkoutSession] = [],
        personalRecords: [PersonalRecord] = [],
        savedWorkoutProgress: [SavedWorkoutProgress] = [],
        settings: AppSettings = .default
    ) {
        self.userProfile = userProfile
        self.activePlan = activePlan
        self.workoutHistory = workoutHistory
        self.personalRecords = personalRecords
        self.savedWorkoutProgress = savedWorkoutProgress
        self.settings = settings
    }

    enum CodingKeys: String, CodingKey {
        case userProfile
        case activePlan
        case workoutHistory
        case personalRecords
        case savedWorkoutProgress
        case settings
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userProfile = try container.decodeIfPresent(UserProfile.self, forKey: .userProfile)
        activePlan = try container.decodeIfPresent(WorkoutPlan.self, forKey: .activePlan)
        workoutHistory = try container.decodeIfPresent([WorkoutSession].self, forKey: .workoutHistory) ?? []
        personalRecords = try container.decodeIfPresent([PersonalRecord].self, forKey: .personalRecords) ?? []
        savedWorkoutProgress = try container.decodeIfPresent([SavedWorkoutProgress].self, forKey: .savedWorkoutProgress) ?? []
        settings = try container.decodeIfPresent(AppSettings.self, forKey: .settings) ?? .default
    }
}

struct SavedWorkoutProgress: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var workoutDayID: UUID
    var weekNumber: Int
    var title: String
    var startedAt: Date
    var savedAt: Date
    var mode: WorkoutTimerMode
    var modeBeforePause: WorkoutTimerMode?
    var currentExerciseIndex: Int
    var currentSetIndex: Int
    var remainingSeconds: Int
    var phaseDurationSeconds: TimeInterval
    var elapsedSeconds: TimeInterval
    var completedSetGroups: [SavedCompletedSetGroup]

    init(
        id: UUID = UUID(),
        workoutDayID: UUID,
        weekNumber: Int,
        title: String,
        startedAt: Date,
        savedAt: Date = Date(),
        mode: WorkoutTimerMode,
        modeBeforePause: WorkoutTimerMode?,
        currentExerciseIndex: Int,
        currentSetIndex: Int,
        remainingSeconds: Int,
        phaseDurationSeconds: TimeInterval,
        elapsedSeconds: TimeInterval,
        completedSetGroups: [SavedCompletedSetGroup]
    ) {
        self.id = id
        self.workoutDayID = workoutDayID
        self.weekNumber = weekNumber
        self.title = title
        self.startedAt = startedAt
        self.savedAt = savedAt
        self.mode = mode
        self.modeBeforePause = modeBeforePause
        self.currentExerciseIndex = currentExerciseIndex
        self.currentSetIndex = currentSetIndex
        self.remainingSeconds = remainingSeconds
        self.phaseDurationSeconds = phaseDurationSeconds
        self.elapsedSeconds = elapsedSeconds
        self.completedSetGroups = completedSetGroups
    }
}

struct SavedCompletedSetGroup: Identifiable, Codable, Equatable, Hashable {
    var id: UUID { exerciseID }
    var exerciseID: UUID
    var sets: [CompletedSet]
}

enum WeekdayWorkoutStatus: String, Equatable {
    case rest
    case upcoming
    case available
    case inProgress
    case completed
    case incomplete
    case missed
}

struct WeekdayWorkoutState: Identifiable, Equatable {
    var id: Int { weekdayIndex }
    var weekdayIndex: Int
    var label: String
    var date: Date
    var deadline: Date
    var workout: WorkoutDay?
    var status: WeekdayWorkoutStatus
}
