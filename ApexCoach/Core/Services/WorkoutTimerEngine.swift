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

    init(workout: WorkoutDay) {
        self.workout = workout
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

    func start() {
        guard mode == .ready, let exercise = currentExercise else { return }
        let now = Date()
        workoutStartedAt = now
        lastResumeAt = now
        transition(to: .work, duration: exercise.workDuration, anchorDate: now)
        HapticEngine.impact(.heavy)
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
        completeCurrentPhase(anchorDate: Date(), setWasSuccessful: true)
        recoverFromClock()
        HapticEngine.impact(.medium)
    }

    func skipSet() {
        guard mode == .work else { return }
        completeCurrentPhase(anchorDate: Date(), setWasSuccessful: false)
        recoverFromClock()
        HapticEngine.impact(.medium)
    }

    func completeSet() {
        guard mode == .work else { return }
        completeCurrentPhase(anchorDate: Date(), setWasSuccessful: true)
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
            completeCurrentPhase(anchorDate: end, setWasSuccessful: true)
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

    private func completeCurrentPhase(anchorDate: Date, setWasSuccessful: Bool) {
        guard let exercise = currentExercise else {
            finish()
            return
        }

        switch mode {
        case .work:
            recordSet(for: exercise, successful: setWasSuccessful, completedAt: anchorDate)
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

    private func recordSet(for exercise: Exercise, successful: Bool, completedAt: Date) {
        let setNumber = currentSetIndex + 1
        if completedSets[exercise.id, default: []].contains(where: { $0.setNumber == setNumber }) {
            return
        }

        let reps = successful ? exercise.targetReps.upperBound : max(0, exercise.targetReps.lowerBound - 1)
        let set = CompletedSet(
            setNumber: setNumber,
            targetReps: exercise.targetReps,
            completedReps: reps,
            weight: exercise.suggestedWeight,
            wasSuccessful: successful,
            completedAt: completedAt
        )
        completedSets[exercise.id, default: []].append(set)
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
