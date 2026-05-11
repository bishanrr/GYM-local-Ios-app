import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @State private var activeWorkout: WorkoutLaunch?
    @State private var selectedWeekdayIndex: Int?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    greeting
                    weeklyProgressCard
                    if let dayState = selectedDayState {
                        selectedDayCard(dayState)
                    } else {
                        EmptyStateView(
                            title: "No workout loaded",
                            subtitle: "Generate a local plan from your profile to start training.",
                            systemImage: "calendar.badge.exclamationmark"
                        )
                    }
                    thisWeekCard
                    volumeCard
                }
                .padding(20)
                .padding(.bottom, 10)
            }
            .navigationTitle("")
            .coachInlineNavigationTitle()
            .background(CoachTheme.background)
        }
        .onAppear {
            selectedWeekdayIndex = selectedDayState?.weekdayIndex
        }
        .coachFullScreenCover(item: $activeWorkout) { launch in
            ActiveWorkoutView(workout: launch.workout, savedProgress: launch.savedProgress)
                .environmentObject(appModel)
        }
    }

    private var selectedDayState: WeekdayWorkoutState? {
        let states = appModel.weeklyDayStates
        if let selectedWeekdayIndex,
           let selected = states.first(where: { $0.weekdayIndex == selectedWeekdayIndex }) {
            return selected
        }
        return appModel.suggestedWeekdayState
    }

    private var greeting: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Good morning,")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(CoachTheme.secondaryText)
                Text(appModel.snapshot.userProfile?.name ?? "Alex")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(CoachTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            Spacer()
            GlassIconButton(systemImage: "bell", title: "Notifications") {}
        }
        .padding(.top, 8)
    }

    private var weeklyProgressCard: some View {
        PremiumCard {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Weekly Progress")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(CoachTheme.secondaryText)
                    Text("\(appModel.completedWorkoutCountThisWeek) / \(appModel.activeWeek?.days.count ?? 0) Workouts")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(CoachTheme.primaryText)
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.10))
                            Capsule()
                                .fill(CoachTheme.accentGradient)
                                .frame(width: proxy.size.width * appModel.weeklyProgress)
                        }
                    }
                    .frame(height: 8)
                }

                ProgressRing(progress: appModel.weeklyProgress, lineWidth: 7)
                    .frame(width: 58, height: 58)
                    .overlay {
                        Text("\(Int(appModel.weeklyProgress * 100))%")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(CoachTheme.primaryText)
                    }
            }
        }
    }

    @ViewBuilder
    private func selectedDayCard(_ state: WeekdayWorkoutState) -> some View {
        if let workout = state.workout {
            workoutCard(workout, state: state)
        } else {
            restDayCard(state)
        }
    }

    private func workoutCard(_ workout: WorkoutDay, state: WeekdayWorkoutState) -> some View {
        let savedProgress = appModel.savedProgress(for: workout)

        return ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [CoachTheme.surfaceStrong.opacity(0.96), CoachTheme.surface.opacity(0.82), Color.black.opacity(0.25)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(CoachTheme.stroke, lineWidth: 1)
                )

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 8) {
                            Text("\(weekdayName(for: state.date)) Workout")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(CoachTheme.secondaryText)
                            statusBadge(for: state.status)
                        }
                        .font(.caption.weight(.bold))
                        Text(workout.title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(CoachTheme.primaryText)
                            .lineLimit(2)
                        Text(workout.muscleFocus.prefix(3).map(\.rawValue).joined(separator: " • "))
                            .font(.subheadline)
                            .foregroundStyle(CoachTheme.secondaryText)
                            .lineLimit(1)
                        Text(statusDetail(for: state))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(statusColor(for: state.status))
                            .lineLimit(1)
                    }

                    if appModel.canStartWorkout(state) {
                        VStack(alignment: .leading, spacing: 8) {
                            Button {
                                activeWorkout = WorkoutLaunch(workout: workout, savedProgress: savedProgress)
                            } label: {
                                HStack(spacing: 10) {
                                    Text(actionTitle(for: state.status))
                                        .font(.headline.weight(.semibold))
                                    Image(systemName: "play.circle.fill")
                                        .font(.title3)
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .frame(height: 52)
                                .background(CoachTheme.accentGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)

                            if savedProgress != nil {
                                Button {
                                    appModel.clearSavedProgress(for: workout)
                                    activeWorkout = WorkoutLaunch(workout: workout, savedProgress: nil)
                                } label: {
                                    Label("Restart Workout", systemImage: "arrow.counterclockwise")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(CoachTheme.secondaryText)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        HStack(spacing: 10) {
                            Image(systemName: state.status == .completed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.title3)
                            Text(state.status == .completed ? "Completed" : "Missed")
                                .font(.headline.weight(.semibold))
                        }
                        .foregroundStyle(statusColor(for: state.status))
                        .padding(.horizontal, 16)
                        .frame(height: 52)
                        .background(statusColor(for: state.status).opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                .padding(16)

                Spacer()

                HeroMuscleFigure(
                    primaryMuscles: workout.muscleFocus,
                    secondaryMuscles: workout.exercises.flatMap(\.secondaryMuscles),
                    pose: .standing
                )
                .frame(width: 132, height: 190)
                .padding(.trailing, 8)
                .padding(.bottom, 2)
            }
        }
        .frame(height: 202)
    }

    private func restDayCard(_ state: WeekdayWorkoutState) -> some View {
        PremiumCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(CoachTheme.surfaceStrong)
                        .frame(width: 64, height: 64)
                    Image(systemName: "moon.stars.fill")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CoachTheme.accentMint)
                }

                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 8) {
                        Text(weekdayName(for: state.date))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(CoachTheme.secondaryText)
                        statusBadge(for: .rest)
                    }
                    Text("Rest Day")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(CoachTheme.primaryText)
                    Text("No workout is scheduled for \(shortDate(for: state.date)).")
                        .font(.subheadline)
                        .foregroundStyle(CoachTheme.secondaryText)
                }
                Spacer()
            }
        }
    }

    private var thisWeekCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("This Week")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CoachTheme.primaryText)
                Spacer()
                Button {
                    appModel.selectedTab = .workouts
                } label: {
                    Text("View all")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CoachTheme.secondaryText)
                }
                .buttonStyle(.plain)
            }

            WeekProgressStrip(
                states: appModel.weeklyDayStates,
                selectedDayIndex: selectedDayState?.weekdayIndex
            ) { state in
                selectedWeekdayIndex = state.weekdayIndex
            }
        }
    }

    private var volumeCard: some View {
        PremiumCard {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Volume")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(CoachTheme.secondaryText)
                    Text(appModel.progressMetrics.weeklyVolume == 0 ? "12,450 kg" : "\(appModel.progressMetrics.weeklyVolume.compactNumber) \(appModel.snapshot.settings.units.weightUnit)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(CoachTheme.primaryText)
                }
                Spacer()
                MiniVolumeChart(values: [4, 7, 11, 6, 10, 5, 12], highlightedIndex: Calendar.current.component(.weekday, from: Date()) - 1)
                    .frame(width: 128)
            }
        }
    }

    private func actionTitle(for status: WeekdayWorkoutStatus) -> String {
        switch status {
        case .inProgress:
            return "Resume Workout"
        case .incomplete:
            return "Retry Workout"
        case .upcoming:
            return "Start Early"
        default:
            return "Start Workout"
        }
    }

    private func statusBadge(for status: WeekdayWorkoutStatus) -> some View {
        Text(statusTitle(for: status))
            .font(.caption2.weight(.bold))
            .foregroundStyle(statusColor(for: status))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(for: status).opacity(0.14))
            .clipShape(Capsule())
    }

    private func statusTitle(for status: WeekdayWorkoutStatus) -> String {
        switch status {
        case .completed:
            return "Completed"
        case .inProgress:
            return "In Progress"
        case .incomplete:
            return "Incomplete"
        case .missed:
            return "Missed"
        case .upcoming:
            return "Upcoming"
        case .available:
            return "Due"
        case .rest:
            return "Rest"
        }
    }

    private func statusDetail(for state: WeekdayWorkoutState) -> String {
        switch state.status {
        case .completed:
            return "Logged locally"
        case .inProgress:
            return "Progress saved. Resume or restart when ready."
        case .incomplete:
            return "Incomplete attempt. Finish by \(shortDate(for: state.deadline))."
        case .missed:
            return "Completion window closed \(shortDate(for: state.deadline))."
        case .upcoming:
            return "Scheduled for \(shortDate(for: state.date))."
        case .available:
            return "Complete by \(shortDate(for: state.deadline))."
        case .rest:
            return "Recovery day"
        }
    }

    private func statusColor(for status: WeekdayWorkoutStatus) -> Color {
        switch status {
        case .completed:
            return CoachTheme.accentMint
        case .inProgress:
            return CoachTheme.accentPurple
        case .incomplete, .missed:
            return CoachTheme.accentCoral
        case .upcoming:
            return CoachTheme.accentGold
        case .available:
            return CoachTheme.accentBlue
        case .rest:
            return CoachTheme.tertiaryText
        }
    }

    private func weekdayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private func shortDate(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

private struct WorkoutLaunch: Identifiable {
    let id = UUID()
    var workout: WorkoutDay
    var savedProgress: SavedWorkoutProgress?
}
