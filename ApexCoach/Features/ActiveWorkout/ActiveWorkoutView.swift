import SwiftUI

struct ActiveWorkoutView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: ActiveWorkoutViewModel
    @State private var recordedSessionID: UUID?

    init(workout: WorkoutDay) {
        _viewModel = StateObject(wrappedValue: ActiveWorkoutViewModel(workout: workout))
    }

    var body: some View {
        ZStack {
            CoachTheme.background.ignoresSafeArea()

            if viewModel.mode == .finished {
                completionView
            } else if viewModel.mode == .rest {
                RestScreen(viewModel: viewModel)
            } else {
                workScreen
            }
        }
        .onAppear {
            viewModel.start()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                viewModel.recoverFromClock()
            }
        }
        .onChange(of: viewModel.mode) { _, mode in
            if mode == .finished {
                recordCompletedSessionIfNeeded()
            }
        }
    }

    private var workScreen: some View {
        VStack(spacing: 18) {
            topBar

            if let exercise = viewModel.currentExercise {
                ScrollView {
                    VStack(spacing: 20) {
                        MuscleDiagramView(
                            primaryMuscles: exercise.primaryMuscles,
                            secondaryMuscles: exercise.secondaryMuscles,
                            side: .front
                        )
                        .frame(maxHeight: 310)

                        timerBlock(title: viewModel.mode == .paused ? "Paused" : viewModel.mode.title)

                        VStack(spacing: 8) {
                            Text(exercise.name)
                                .font(.title.weight(.bold))
                                .foregroundStyle(CoachTheme.primaryText)
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.72)
                            Text(viewModel.setLabel)
                                .font(.headline)
                                .foregroundStyle(CoachTheme.accentMint)
                            Text("\(exercise.targetReps.label) reps" + weightText(for: exercise))
                                .font(.subheadline)
                                .foregroundStyle(CoachTheme.secondaryText)
                        }

                        if let next = viewModel.nextExercise {
                            PremiumCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Next Exercise")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(CoachTheme.accentBlue)
                                    ExerciseSummaryRow(exercise: next, showsAccessory: false)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }

            controls
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
    }

    private var topBar: some View {
        HStack {
            GlassIconButton(systemImage: "xmark", title: "End") {
                recordPartialAndDismiss()
            }

            Spacer()

            VStack(spacing: 2) {
                Text(viewModel.workout.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CoachTheme.primaryText)
                    .lineLimit(1)
                Text("Live \(viewModel.elapsedText)")
                    .font(.caption)
                    .foregroundStyle(CoachTheme.secondaryText)
            }

            Spacer()

            GlassIconButton(systemImage: viewModel.mode == .paused ? "play.fill" : "pause.fill", title: "Pause") {
                viewModel.pauseOrResume()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    private func timerBlock(title: String) -> some View {
        ZStack {
            ProgressRing(progress: viewModel.phaseProgress, lineWidth: 14)
                .frame(width: 210, height: 210)
            VStack(spacing: 8) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(CoachTheme.secondaryText)
                Text(viewModel.remainingText)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(CoachTheme.primaryText)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            PrimaryCoachButton(
                title: viewModel.mode == .paused ? "Resume Workout" : "Pause Workout",
                systemImage: viewModel.mode == .paused ? "play.fill" : "pause.fill"
            ) {
                viewModel.pauseOrResume()
            }

            HStack(spacing: 12) {
                Button {
                    viewModel.skipSet()
                } label: {
                    Label("Skip Set", systemImage: "forward.end.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(SecondaryControlButtonStyle())

                Button(role: .destructive) {
                    recordPartialAndDismiss()
                } label: {
                    Label("End", systemImage: "stop.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(SecondaryControlButtonStyle(tint: CoachTheme.accentCoral))
            }
        }
    }

    private var completionView: some View {
        VStack(spacing: 22) {
            Spacer()
            ProgressRing(progress: 1, lineWidth: 12, gradient: CoachTheme.warmGradient)
                .frame(width: 128, height: 128)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)
                }

            VStack(spacing: 8) {
                Text("Workout Complete")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(CoachTheme.primaryText)
                Text("Progress saved locally. Your next week will adapt when this week is complete.")
                    .font(.subheadline)
                    .foregroundStyle(CoachTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            MetricPill(title: "Session Time", value: viewModel.elapsedText, systemImage: "timer", tint: CoachTheme.accentMint)
                .padding(.horizontal, 32)

            Spacer()

            PrimaryCoachButton(title: "Done", systemImage: "checkmark") {
                dismiss()
            }
            .padding(20)
        }
    }

    private func recordCompletedSessionIfNeeded() {
        guard recordedSessionID == nil else { return }
        let session = viewModel.completedSession()
        recordedSessionID = session.id
        appModel.recordCompletedWorkout(session)
    }

    private func recordPartialAndDismiss() {
        guard recordedSessionID == nil else {
            dismiss()
            return
        }
        let session = viewModel.endWorkout(markCompleted: false)
        recordedSessionID = session.id
        appModel.recordCompletedWorkout(session)
        dismiss()
    }

    private func weightText(for exercise: Exercise) -> String {
        guard let weight = exercise.suggestedWeight else { return "" }
        return " • \(Int(weight)) \(appModel.snapshot.settings.units.weightUnit)"
    }
}

private struct RestScreen: View {
    @ObservedObject var viewModel: ActiveWorkoutViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Rest")
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(CoachTheme.accentMint)

            timer

            Text(motivationalText)
                .font(.title3.weight(.semibold))
                .foregroundStyle(CoachTheme.primaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            if let next = viewModel.nextExercise ?? viewModel.currentExercise {
                PremiumCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Upcoming")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(CoachTheme.accentBlue)
                        ExerciseSummaryRow(exercise: next, showsAccessory: false)
                    }
                }
                .padding(.horizontal, 20)
            }

            Spacer()

            PrimaryCoachButton(title: "Skip Rest", systemImage: "forward.fill") {
                viewModel.skipRest()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 22)
        }
    }

    private var timer: some View {
        ZStack {
            ProgressRing(progress: viewModel.phaseProgress, lineWidth: 16)
                .frame(width: 240, height: 240)
            Text(viewModel.remainingText)
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .foregroundStyle(CoachTheme.primaryText)
                .monospacedDigit()
        }
    }

    private var motivationalText: String {
        let lines = [
            "Breathe low. Own the next set.",
            "Stay loose. The next rep starts before the timer ends.",
            "Reset your grip, reset your intent.",
            "Smooth work beats rushed work."
        ]
        return lines[Int(Date().timeIntervalSince1970) % lines.count]
    }
}

private struct SecondaryControlButtonStyle: ButtonStyle {
    var tint: Color = CoachTheme.accentBlue

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(tint)
            .background(CoachTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(tint.opacity(configuration.isPressed ? 0.72 : 0.28), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
