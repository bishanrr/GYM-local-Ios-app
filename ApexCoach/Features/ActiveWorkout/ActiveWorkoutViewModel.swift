import Foundation
import Combine

@MainActor
final class ActiveWorkoutViewModel: ObservableObject {
    let engine: WorkoutTimerEngine
    private var cancellables = Set<AnyCancellable>()

    init(workout: WorkoutDay) {
        engine = WorkoutTimerEngine(workout: workout)
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

    func start() {
        engine.start()
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

    func recoverFromClock() {
        engine.recoverFromClock()
    }

    func completedSession() -> WorkoutSession {
        engine.completedSession()
    }

    func endWorkout(markCompleted: Bool = false) -> WorkoutSession {
        engine.endWorkout(markCompleted: markCompleted)
    }
}
