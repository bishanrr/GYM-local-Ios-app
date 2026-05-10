import Foundation
import Combine

@MainActor
final class ActiveWorkoutViewModel: ObservableObject {
    let engine: WorkoutTimerEngine
    private var cancellables = Set<AnyCancellable>()

    init(workout: WorkoutDay, savedProgress: SavedWorkoutProgress? = nil) {
        engine = WorkoutTimerEngine(workout: workout, savedProgress: savedProgress)
        engine.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    var workout: WorkoutDay { engine.workout }
    var mode: WorkoutTimerMode { engine.mode }
    var currentExercise: Exercise? { engine.currentExercise }
    var nextExercise: Exercise? { engine.nextExercise }
    var setLabel: String { engine.setLabel }
    var remainingText: String { TimeInterval(engine.remainingSeconds).clockString }
    var elapsedText: String { engine.elapsedSeconds.clockString }
    var phaseProgress: Double { engine.phaseProgress }
    var phaseDurationSeconds: TimeInterval { engine.phaseDurationSeconds }
    var completedSetCount: Int { engine.completedSetCount }
    var totalSetCount: Int { engine.totalSetCount }
    var remainingSetCount: Int { engine.remainingSetCount }
    var setProgress: Double {
        guard totalSetCount > 0 else { return 0 }
        return Double(completedSetCount) / Double(totalSetCount)
    }
    var totalWorkoutTimeText: String { engine.totalWorkoutDurationSeconds.clockString }
    var remainingWorkoutTimeText: String { engine.remainingWorkoutDurationSeconds.clockString }
    var workoutProgress: Double { engine.workoutProgress }

    func start() {
        engine.start()
    }

    func restart() {
        engine.restart()
    }

    func pauseOrResume() {
        if engine.mode == .paused {
            engine.resume()
        } else {
            engine.pause()
        }
    }

    func skipRest() {
        engine.skipRest()
    }

    func skipSet() {
        engine.skipSet()
    }

    func completeSet(reps: Int, weight: Double?) {
        engine.completeSet(reps: reps, weight: weight)
    }

    func recoverFromClock() {
        engine.recoverFromClock()
    }

    func completedSession() -> WorkoutSession {
        engine.completedSession()
    }

    func savedProgress() -> SavedWorkoutProgress {
        engine.savedProgress()
    }

    func endWorkout(markCompleted: Bool = false) -> WorkoutSession {
        engine.endWorkout(markCompleted: markCompleted)
    }
}
