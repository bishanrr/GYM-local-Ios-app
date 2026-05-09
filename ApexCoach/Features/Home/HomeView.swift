import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @State private var activeWorkout: WorkoutDay?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    greeting
                    if let workout = appModel.todayWorkout {
                        todayWorkoutCard(workout)
                    } else {
                        EmptyStateView(
                            title: "No workout loaded",
                            subtitle: "Generate a local plan from your profile to start training.",
                            systemImage: "calendar.badge.exclamationmark"
                        )
                    }
                    weeklyOverview
                    muscleFocusSummary
                }
                .padding(20)
            }
            .navigationTitle("Today")
            .coachInlineNavigationTitle()
            .background(CoachTheme.background)
        }
        .coachFullScreenCover(item: $activeWorkout) { workout in
            ActiveWorkoutView(workout: workout)
                .environmentObject(appModel)
        }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Ready, \(appModel.snapshot.userProfile?.name ?? "Athlete")")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(CoachTheme.primaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
            Text(appModel.snapshot.activePlan?.summary ?? "Your offline coach is ready.")
                .font(.subheadline)
                .foregroundStyle(CoachTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func todayWorkoutCard(_ workout: WorkoutDay) -> some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Today’s Workout")
                            .font(.caption.weight(.semibold))
                            .textCase(.uppercase)
                            .foregroundStyle(CoachTheme.accentMint)
                        Text(workout.title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(CoachTheme.primaryText)
                            .lineLimit(2)
                    }
                    Spacer()
                    ProgressRing(progress: appModel.weeklyProgress, lineWidth: 8)
                        .frame(width: 58, height: 58)
                        .overlay {
                            Text("\(Int(appModel.weeklyProgress * 100))%")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(CoachTheme.primaryText)
                        }
                }

                MuscleDiagramView(
                    primaryMuscles: workout.muscleFocus,
                    secondaryMuscles: workout.exercises.flatMap(\.secondaryMuscles),
                    side: .front
                )
                .frame(maxHeight: 320)

                HStack(spacing: 10) {
                    MetricPill(title: "Duration", value: "\(workout.estimatedDurationMinutes)m", systemImage: "timer", tint: CoachTheme.accentBlue)
                    MetricPill(title: "Calories", value: "\(appModel.estimatedCaloriesForToday)", systemImage: "flame.fill", tint: CoachTheme.accentCoral)
                }

                PrimaryCoachButton(title: "Start Workout", systemImage: "play.fill") {
                    activeWorkout = workout
                }
            }
        }
    }

    private var weeklyOverview: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(
                    title: "Weekly Progress",
                    subtitle: "\(appModel.completedWorkoutCountThisWeek) of \(appModel.activeWeek?.days.count ?? 0) workouts complete"
                )

                HStack(spacing: 14) {
                    MetricPill(title: "Streak", value: "\(appModel.progressMetrics.currentStreak)d", systemImage: "bolt.heart.fill", tint: CoachTheme.accentGold)
                    MetricPill(title: "Volume", value: appModel.progressMetrics.weeklyVolume.compactNumber, systemImage: "chart.bar.fill", tint: CoachTheme.accentMint)
                }
            }
        }
    }

    private var muscleFocusSummary: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Muscle Focus", subtitle: "Primary activation for the next session.")
                let muscles = appModel.todayWorkout?.muscleFocus ?? []
                if muscles.isEmpty {
                    Text("No focus selected")
                        .foregroundStyle(CoachTheme.secondaryText)
                } else {
                    FlowLayout(items: muscles.map(\.rawValue))
                }
            }
        }
    }
}

private struct FlowLayout: View {
    var items: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CoachTheme.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(CoachTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }
}
