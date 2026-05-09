import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @State private var activeWorkout: WorkoutDay?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    greeting
                    weeklyProgressCard
                    if let workout = appModel.todayWorkout {
                        todayWorkoutCard(workout)
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
        .coachFullScreenCover(item: $activeWorkout) { workout in
            ActiveWorkoutView(workout: workout)
                .environmentObject(appModel)
        }
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

    private func todayWorkoutCard(_ workout: WorkoutDay) -> some View {
        ZStack(alignment: .bottomLeading) {
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
                        Text("Today’s Workout")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(CoachTheme.secondaryText)
                        Text(workout.title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(CoachTheme.primaryText)
                            .lineLimit(2)
                        Text(workout.muscleFocus.prefix(3).map(\.rawValue).joined(separator: " • "))
                            .font(.subheadline)
                            .foregroundStyle(CoachTheme.secondaryText)
                            .lineLimit(1)
                    }

                    Button {
                        activeWorkout = workout
                    } label: {
                        HStack(spacing: 10) {
                            Text("Start Workout")
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

    private var thisWeekCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("This Week")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CoachTheme.primaryText)
                Spacer()
                Text("View all")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CoachTheme.secondaryText)
            }

            WeekProgressStrip(
                completedCount: appModel.completedWorkoutCountThisWeek,
                totalCount: appModel.activeWeek?.days.count ?? 0
            )
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
}
