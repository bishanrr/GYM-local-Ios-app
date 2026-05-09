import SwiftUI

struct ActiveWorkoutView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: ActiveWorkoutViewModel
    @State private var recordedSessionID: UUID?
    @State private var repsValue: Int = 8
    @State private var weightValue: Int = 80

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
            syncEditableTargets()
            viewModel.start()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                viewModel.recoverFromClock()
            }
        }
        .onChange(of: viewModel.currentExercise?.id) { _, _ in
            syncEditableTargets()
        }
        .onChange(of: viewModel.mode) { _, mode in
            if mode == .finished {
                recordCompletedSessionIfNeeded()
            }
        }
    }

    private var workScreen: some View {
        VStack(spacing: 0) {
            topBar

            if let exercise = viewModel.currentExercise {
                ScrollView {
                    VStack(spacing: 18) {
                        hero(for: exercise)
                        activeTimerCard(for: exercise)

                        VStack(spacing: 12) {
                            ValueStepperCard(title: "Reps", value: $repsValue, range: 0...50)
                            ValueStepperCard(title: "Weight (\(appModel.snapshot.settings.units.weightUnit))", value: $weightValue, range: 0...600, step: 5)
                        }

                        PrimaryCoachButton(title: completeButtonTitle(for: exercise), systemImage: "checkmark") {
                            viewModel.completeSet()
                        }

                        restTimerRow(for: exercise)

                        if let next = viewModel.nextExercise {
                            PremiumCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Up Next")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(CoachTheme.secondaryText)
                                    ExerciseSummaryRow(exercise: next, showsAccessory: false)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 16)
                }
            }
        }
    }

    private var topBar: some View {
        HStack {
            GlassIconButton(systemImage: "xmark", title: "End") {
                recordPartialAndDismiss()
            }

            Spacer()

            VStack(spacing: 3) {
                Text(viewModel.currentExercise?.name ?? viewModel.workout.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(CoachTheme.primaryText)
                    .lineLimit(1)
                Text(viewModel.setLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CoachTheme.secondaryText)
            }

            Spacer()

            GlassIconButton(systemImage: viewModel.mode == .paused ? "play.fill" : "pause.fill", title: "Pause") {
                viewModel.pauseOrResume()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private func hero(for exercise: Exercise) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.055), Color.black.opacity(0.34)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(CoachTheme.stroke, lineWidth: 1)
                )

            HeroMuscleFigure(
                primaryMuscles: exercise.primaryMuscles,
                secondaryMuscles: exercise.secondaryMuscles,
                pose: exercise.primaryMuscles.contains(.chest) ? .bench : .standing
            )
            .frame(height: 230)
            .padding(.horizontal, 26)
            .padding(.top, 18)
        }
        .frame(height: 250)
    }

    private func activeTimerCard(for exercise: Exercise) -> some View {
        HStack(spacing: 18) {
            ZStack {
                ProgressRing(progress: viewModel.phaseProgress, lineWidth: 13, gradient: CoachTheme.accentGradient)
                    .frame(width: 152, height: 152)
                VStack(spacing: 5) {
                    Text(viewModel.mode == .paused ? "Paused" : exercise.phase.rawValue)
                        .font(.caption2.weight(.bold))
                        .textCase(.uppercase)
                        .foregroundStyle(CoachTheme.secondaryText)
                    Text(viewModel.remainingText)
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(CoachTheme.primaryText)
                        .monospacedDigit()
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(exercise.phase == .main ? "Set Timer" : "\(exercise.phase.rawValue) Timer")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CoachTheme.primaryText)
                Text("Auto advances into rest, the next set, or the next exercise.")
                    .font(.subheadline)
                    .foregroundStyle(CoachTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Live \(viewModel.elapsedText)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(CoachTheme.accentBlue)
                    .monospacedDigit()
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(CoachTheme.surface.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(CoachTheme.stroke, lineWidth: 1)
        )
    }

    private func restTimerRow(for exercise: Exercise) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "timer")
                .font(.title3)
                .foregroundStyle(CoachTheme.secondaryText)
                .frame(width: 38, height: 38)
                .background(CoachTheme.surfaceStrong)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("Rest Timer")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(CoachTheme.secondaryText)
                Text(exercise.restDuration.clockString)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(CoachTheme.primaryText)
                    .monospacedDigit()
            }

            Spacer()

            Button {
                viewModel.skipSet()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(CoachTheme.secondaryText)
                    .frame(width: 42, height: 42)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(CoachTheme.surface.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(CoachTheme.stroke, lineWidth: 1)
        )
    }

    private var completionView: some View {
        VStack(spacing: 22) {
            Spacer()
            ProgressRing(progress: 1, lineWidth: 12, gradient: CoachTheme.accentGradient)
                .frame(width: 132, height: 132)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)
                }

            Text("Workout Complete")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(CoachTheme.primaryText)
            Text("Progress saved locally. Warm-up, work, and stretching are all logged on device.")
                .font(.subheadline)
                .foregroundStyle(CoachTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            MetricPill(title: "Session Time", value: viewModel.elapsedText, systemImage: "timer", tint: CoachTheme.accentBlue)
                .padding(.horizontal, 32)

            Spacer()

            PrimaryCoachButton(title: "Done", systemImage: "checkmark") {
                dismiss()
            }
            .padding(20)
        }
    }

    private func completeButtonTitle(for exercise: Exercise) -> String {
        switch exercise.phase {
        case .warmUp:
            return "Complete Warm Up"
        case .stretching:
            return "Complete Stretch"
        case .main:
            return "Complete Set"
        }
    }

    private func syncEditableTargets() {
        guard let exercise = viewModel.currentExercise else { return }
        repsValue = exercise.targetReps.upperBound
        weightValue = Int(exercise.suggestedWeight ?? 0)
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
}

private struct ValueStepperCard: View {
    var title: String
    @Binding var value: Int
    var range: ClosedRange<Int>
    var step: Int = 1

    var body: some View {
        HStack {
            Button {
                value = max(range.lowerBound, value - step)
            } label: {
                Image(systemName: "minus")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(CoachTheme.primaryText)
                    .frame(width: 44, height: 44)
                    .background(CoachTheme.surfaceStrong)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 8) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(CoachTheme.secondaryText)
                Text("\(value)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(CoachTheme.primaryText)
                    .monospacedDigit()
            }

            Spacer()

            Button {
                value = min(range.upperBound, value + step)
            } label: {
                Image(systemName: "plus")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(CoachTheme.primaryText)
                    .frame(width: 44, height: 44)
                    .background(CoachTheme.surfaceStrong)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(CoachTheme.surface.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(CoachTheme.stroke, lineWidth: 1)
        )
    }
}

private struct RestScreen: View {
    @ObservedObject var viewModel: ActiveWorkoutViewModel

    var body: some View {
        VStack(spacing: 22) {
            HStack {
                Spacer()
                Text("Rest")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(CoachTheme.primaryText)
                Spacer()
                GlassIconButton(systemImage: "xmark", title: "Close") {
                    viewModel.skipRest()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)

            Spacer()
            timer
            Spacer()

            VStack(alignment: .leading, spacing: 14) {
                Text("Up Next")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CoachTheme.primaryText)

                if let next = viewModel.nextExercise ?? viewModel.currentExercise {
                    ExerciseListLikeRow(exercise: next)
                }
            }
            .padding(.horizontal, 20)

            Button {
                viewModel.skipRest()
            } label: {
                Text("Skip Rest")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CoachTheme.primaryText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(Color.white.opacity(0.035))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.28), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 22)
        }
    }

    private var timer: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width - 24, 336)
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [CoachTheme.accentBlue.opacity(0.13), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: size * 0.62
                        )
                    )
                    .frame(width: size + 34, height: size + 34)

                ProgressRing(progress: viewModel.phaseProgress, lineWidth: 24, gradient: CoachTheme.accentGradient)
                    .frame(width: size, height: size)
                VStack(spacing: 10) {
                    Text(viewModel.remainingText)
                        .font(.system(size: 78, weight: .bold, design: .rounded))
                        .foregroundStyle(CoachTheme.primaryText)
                        .monospacedDigit()
                        .minimumScaleFactor(0.76)
                    Text("/ \(viewModel.phaseDurationSeconds.clockString)")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(CoachTheme.secondaryText)
                        .monospacedDigit()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 360)
    }
}

private struct ExerciseListLikeRow: View {
    var exercise: Exercise

    var body: some View {
        HStack(spacing: 14) {
            WorkoutThumbnail(primaryMuscles: exercise.primaryMuscles, secondaryMuscles: exercise.secondaryMuscles, phase: exercise.phase)
                .frame(width: 58, height: 58)
            VStack(alignment: .leading, spacing: 5) {
                Text(exercise.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CoachTheme.primaryText)
                Text(exercise.phase == .main ? "\(exercise.sets) sets x \(exercise.targetReps.label) reps" : "\(Int(exercise.workDuration)) sec")
                    .font(.subheadline)
                    .foregroundStyle(CoachTheme.secondaryText)
            }
            Spacer()
        }
        .padding(12)
        .background(CoachTheme.surface.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(CoachTheme.stroke, lineWidth: 1)
        )
    }
}
