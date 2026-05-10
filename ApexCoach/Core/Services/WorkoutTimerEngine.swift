import Foundation
import Combine

enum WorkoutTimerMode: String, Codable, Equatable {
    case ready
    case work
    case rest
    case paused
    case finished

    var title: String {
        switch self {
        case .ready:
            return "Ready"
        case .work:
            return "Set"
        case .rest:
            return "Rest"
        case .paused:
            return "Paused"
        case .finished:
            return "Complete"
        }
    }
}

@MainActor
final class WorkoutTimerEngine: ObservableObject {
    @Published private(set) var mode: WorkoutTimerMode = .ready
    @Published private(set) var currentExerciseIndex = 0
    @Published private(set) var currentSetIndex = 0
    @Published private(set) var remainingSeconds = 0
    @Published private(set) var elapsedSeconds: TimeInterval = 0

    let workout: WorkoutDay

    private var phaseEndsAt: Date?
    private var currentPhaseDuration: TimeInterval = 1
    private var modeBeforePause: WorkoutTimerMode?
    private var workoutStartedAt: Date?
    private var lastResumeAt: Date?
    private var elapsedBeforePause: TimeInterval = 0
    private var ticker: Task<Void, Never>?
    private var completedSets: [UUID: [CompletedSet]] = [:]

    init(workout: WorkoutDay, savedProgress: SavedWorkoutProgress? = nil) {
        self.workout = workout
        if let savedProgress {
            restore(from: savedProgress)
        }
    }

    deinit {
        ticker?.cancel()
    }

    var currentExercise: Exercise? {
        guard workout.exercises.indices.contains(currentExerciseIndex) else { return nil }
        return workout.exercises[currentExerciseIndex]
    }

    var nextExercise: Exercise? {
        let index = currentExerciseIndex + 1
        guard workout.exercises.indices.contains(index) else { return nil }
        return workout.exercises[index]
    }

    var setLabel: String {
        guard let exercise = currentExercise else { return "Set 0 of 0" }
        return "Set \(currentSetIndex + 1) of \(exercise.sets)"
    }

    var phaseProgress: Double {
        guard currentPhaseDuration > 0 else { return 0 }
        return max(0, min(1, 1 - (Double(remainingSeconds) / currentPhaseDuration)))
    }

    var phaseDurationSeconds: TimeInterval {
        currentPhaseDuration
    }

    var totalSetCount: Int {
        workout.exercises.reduce(0) { $0 + $1.sets }
    }

    var completedSetCount: Int {
        completedSets.values.reduce(0) { $0 + $1.count }
    }

    var remainingSetCount: Int {
        max(totalSetCount - completedSetCount, 0)
    }

    var totalRepCount: Int {
        workout.exercises.reduce(0) { $0 + ($1.sets * $1.targetReps.upperBound) }
    }

    var completedRepCount: Int {
        completedSets.values.flatMap { $0 }.reduce(0) { $0 + $1.completedReps }
    }

    var remainingRepCount: Int {
        max(totalRepCount - completedRepCount, 0)
    }

    var totalWorkoutDurationSeconds: TimeInterval {
        workout.exercises.reduce(0) { total, exercise in
            total + (Double(exercise.sets) * (exercise.workDuration + exercise.restDuration))
        }
    }

    var remainingWorkoutDurationSeconds: TimeInterval {
        guard mode != .finished else { return 0 }
        guard !workout.exercises.isEmpty else { return 0 }
        guard mode != .ready else { return totalWorkoutDurationSeconds }

        let currentRemaining = TimeInterval(max(remainingSeconds, 0))
        var future: TimeInterval = 0

        let effectiveMode = mode == .paused ? (modeBeforePause ?? .work) : mode
        switch effectiveMode {
        case .work:
            if let exercise = currentExercise {
                future += exercise.restDuration
                let remainingSetsInExercise = max(exercise.sets - currentSetIndex - 1, 0)
                future += Double(remainingSetsInExercise) * (exercise.workDuration + exercise.restDuration)
            }
            future += remainingDurationForExercises(after: currentExerciseIndex)
        case .rest:
            if let exercise = currentExercise {
                let remainingSetsInExercise = max(exercise.sets - currentSetIndex - 1, 0)
                future += Double(remainingSetsInExercise) * (exercise.workDuration + exercise.restDuration)
            }
            future += remainingDurationForExercises(after: currentExerciseIndex)
        case .paused, .ready, .finished:
            break
        }

        return max(0, currentRemaining + future)
    }

    var workoutProgress: Double {
        let total = totalWorkoutDurationSeconds
        guard total > 0 else { return 0 }
        return max(0, min(1, 1 - (remainingWorkoutDurationSeconds / total)))
    }

    func start() {
        guard mode == .ready, let exercise = currentExercise else { return }
        let now = Date()
        workoutStartedAt = now
        lastResumeAt = now
        transition(to: .work, duration: exercise.workDuration, anchorDate: now)
        HapticEngine.impact(.heavy)
    }

    func restart() {
        ticker?.cancel()
        mode = .ready
        currentExerciseIndex = 0
        currentSetIndex = 0
        remainingSeconds = 0
        elapsedSeconds = 0
        phaseEndsAt = nil
        currentPhaseDuration = 1
        modeBeforePause = nil
        workoutStartedAt = nil
        lastResumeAt = nil
        elapsedBeforePause = 0
        completedSets = [:]
        start()
    }

    func pause() {
        guard mode == .work || mode == .rest else { return }
        modeBeforePause = mode
        if let end = phaseEndsAt {
            remainingSeconds = max(0, Int(ceil(end.timeIntervalSinceNow)))
        }
        if let lastResumeAt {
            elapsedBeforePause += Date().timeIntervalSince(lastResumeAt)
        }
        lastResumeAt = nil
        mode = .paused
        ticker?.cancel()
        HapticEngine.impact(.light)
    }

    func resume() {
        guard mode == .paused else { return }
        let resumedMode = modeBeforePause ?? .work
        let now = Date()
        mode = resumedMode
        lastResumeAt = now
        phaseEndsAt = now.addingTimeInterval(TimeInterval(max(remainingSeconds, 1)))
        startTicker()
        recoverFromClock()
        HapticEngine.impact(.medium)
    }

    func skipRest() {
        guard mode == .rest else { return }
        completeCurrentPhase(anchorDate: Date(), setWasSuccessful: true, reps: nil, weight: nil)
        recoverFromClock()
        HapticEngine.impact(.medium)
    }

    func skipSet() {
        guard mode == .work else { return }
        completeCurrentPhase(anchorDate: Date(), setWasSuccessful: false, reps: nil, weight: nil)
        recoverFromClock()
        HapticEngine.impact(.medium)
    }

    func completeSet(reps: Int? = nil, weight: Double? = nil) {
        guard mode == .work else { return }
        completeCurrentPhase(anchorDate: Date(), setWasSuccessful: true, reps: reps, weight: weight)
        recoverFromClock()
        HapticEngine.impact(.heavy)
    }

    func endWorkout(markCompleted: Bool = false) -> WorkoutSession {
        finish()
        return makeSession(wasCompleted: markCompleted)
    }

    func recoverFromClock() {
        guard mode == .work || mode == .rest else {
            refreshElapsed()
            return
        }

        let now = Date()
        var safetyCounter = 0
        while let end = phaseEndsAt, now >= end, safetyCounter < 100, mode == .work || mode == .rest {
            completeCurrentPhase(anchorDate: end, setWasSuccessful: true, reps: nil, weight: nil)
            safetyCounter += 1
        }

        if let end = phaseEndsAt {
            remainingSeconds = max(0, Int(ceil(end.timeIntervalSince(now))))
        }
        refreshElapsed()
    }

    func completedSession() -> WorkoutSession {
        makeSession(wasCompleted: mode == .finished && completedAllPrescribedSets)
    }

    func savedProgress() -> SavedWorkoutProgress {
        refreshForSnapshot()
        let groups = completedSets.map { exerciseID, sets in
            SavedCompletedSetGroup(exerciseID: exerciseID, sets: sets.sorted { $0.setNumber < $1.setNumber })
        }

        return SavedWorkoutProgress(
            workoutDayID: workout.id,
            weekNumber: workout.weekNumber,
            title: workout.title,
            startedAt: workoutStartedAt ?? Date(),
            mode: mode,
            modeBeforePause: modeBeforePause,
            currentExerciseIndex: currentExerciseIndex,
            currentSetIndex: currentSetIndex,
            remainingSeconds: remainingSeconds,
            phaseDurationSeconds: currentPhaseDuration,
            elapsedSeconds: elapsedSeconds,
            completedSetGroups: groups.sorted { $0.exerciseID.uuidString < $1.exerciseID.uuidString }
        )
    }

    private var completedAllPrescribedSets: Bool {
        workout.exercises.allSatisfy { exercise in
            let successfulSets = completedSets[exercise.id, default: []].filter(\.wasSuccessful).count
            return successfulSets >= exercise.sets
        }
    }

    private func transition(to newMode: WorkoutTimerMode, duration: TimeInterval, anchorDate: Date) {
        mode = newMode
        currentPhaseDuration = max(duration, 1)
        phaseEndsAt = anchorDate.addingTimeInterval(currentPhaseDuration)
        remainingSeconds = Int(ceil(currentPhaseDuration))
        startTicker()
    }

    private func completeCurrentPhase(anchorDate: Date, setWasSuccessful: Bool, reps: Int?, weight: Double?) {
        guard let exercise = currentExercise else {
            finish()
            return
        }

        switch mode {
        case .work:
            recordSet(for: exercise, successful: setWasSuccessful, reps: reps, weight: weight, completedAt: anchorDate)
            if exercise.restDuration > 0 {
                transition(to: .rest, duration: exercise.restDuration, anchorDate: anchorDate)
            } else {
                advanceToNextWork(anchorDate: anchorDate)
            }
        case .rest:
            advanceToNextWork(anchorDate: anchorDate)
        default:
            break
        }
    }

    private func advanceToNextWork(anchorDate: Date) {
        if let exercise = currentExercise, currentSetIndex + 1 < exercise.sets {
            currentSetIndex += 1
            transition(to: .work, duration: exercise.workDuration, anchorDate: anchorDate)
            return
        }

        if currentExerciseIndex + 1 < workout.exercises.count {
            currentExerciseIndex += 1
            currentSetIndex = 0
            let next = workout.exercises[currentExerciseIndex]
            transition(to: .work, duration: next.workDuration, anchorDate: anchorDate)
            HapticEngine.notify(.success)
            return
        }

        finish()
    }

    private func recordSet(for exercise: Exercise, successful: Bool, reps: Int?, weight: Double?, completedAt: Date) {
        let setNumber = currentSetIndex + 1
        if completedSets[exercise.id, default: []].contains(where: { $0.setNumber == setNumber }) {
            return
        }

        let completedReps = max(0, reps ?? (successful ? exercise.targetReps.upperBound : max(0, exercise.targetReps.lowerBound - 1)))
        let set = CompletedSet(
            setNumber: setNumber,
            targetReps: exercise.targetReps,
            completedReps: completedReps,
            weight: weight ?? exercise.suggestedWeight,
            wasSuccessful: successful,
            completedAt: completedAt
        )
        completedSets[exercise.id, default: []].append(set)
    }

    private func restore(from progress: SavedWorkoutProgress) {
        workoutStartedAt = progress.startedAt
        elapsedBeforePause = progress.elapsedSeconds
        elapsedSeconds = progress.elapsedSeconds
        currentExerciseIndex = min(max(progress.currentExerciseIndex, 0), max(workout.exercises.count - 1, 0))
        if let exercise = currentExercise {
            currentSetIndex = min(max(progress.currentSetIndex, 0), max(exercise.sets - 1, 0))
        } else {
            currentSetIndex = 0
        }
        currentPhaseDuration = max(progress.phaseDurationSeconds, 1)
        remainingSeconds = max(progress.remainingSeconds, 1)
        modeBeforePause = progress.modeBeforePause
        completedSets = Dictionary(uniqueKeysWithValues: progress.completedSetGroups.map { ($0.exerciseID, $0.sets) })

        switch progress.mode {
        case .work, .rest:
            mode = progress.mode
            lastResumeAt = Date()
            phaseEndsAt = Date().addingTimeInterval(TimeInterval(remainingSeconds))
            startTicker()
        case .paused:
            mode = .paused
            lastResumeAt = nil
            phaseEndsAt = nil
            modeBeforePause = progress.modeBeforePause ?? .work
        case .ready:
            mode = .ready
            lastResumeAt = nil
            phaseEndsAt = nil
        case .finished:
            mode = .finished
            lastResumeAt = nil
            phaseEndsAt = nil
        }
    }

    private func remainingDurationForExercises(after index: Int) -> TimeInterval {
        let nextIndex = index + 1
        guard workout.exercises.indices.contains(nextIndex) else { return 0 }
        return workout.exercises[nextIndex...].reduce(0) { total, exercise in
            total + (Double(exercise.sets) * (exercise.workDuration + exercise.restDuration))
        }
    }

    private func finish() {
        refreshElapsed(finalize: true)
        mode = .finished
        phaseEndsAt = nil
        remainingSeconds = 0
        ticker?.cancel()
        HapticEngine.notify(.success)
    }

    private func refreshElapsed(finalize: Bool = false) {
        if let lastResumeAt {
            elapsedSeconds = elapsedBeforePause + Date().timeIntervalSince(lastResumeAt)
            if finalize {
                elapsedBeforePause = elapsedSeconds
                self.lastResumeAt = nil
            }
        } else {
            elapsedSeconds = elapsedBeforePause
        }
    }

    private func refreshForSnapshot() {
        if mode == .work || mode == .rest, let end = phaseEndsAt {
            remainingSeconds = max(1, Int(ceil(end.timeIntervalSinceNow)))
        }
        refreshElapsed()
    }

    private func makeSession(wasCompleted: Bool) -> WorkoutSession {
        let started = workoutStartedAt ?? Date()
        let completedExercises = workout.exercises.compactMap { exercise -> CompletedExercise? in
            let sets = completedSets[exercise.id, default: []].sorted { $0.setNumber < $1.setNumber }
            guard !sets.isEmpty else { return nil }
            return CompletedExercise(
                exerciseID: exercise.id,
                exerciseName: exercise.name,
                primaryMuscles: exercise.primaryMuscles,
                sets: sets
            )
        }

        return WorkoutSession(
            workoutDayID: workout.id,
            weekNumber: workout.weekNumber,
            title: workout.title,
            startedAt: started,
            durationSeconds: elapsedSeconds,
            completedExercises: completedExercises,
            wasCompleted: wasCompleted
        )
    }

    private func startTicker() {
        ticker?.cancel()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 250_000_000)
                await MainActor.run {
                    self?.recoverFromClock()
                }
            }
        }
    }
}
