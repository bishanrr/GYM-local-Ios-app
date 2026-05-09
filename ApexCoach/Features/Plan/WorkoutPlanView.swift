import SwiftUI

struct WorkoutPlanView: View {
    @EnvironmentObject private var appModel: AppViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    planHeader
                    if let week = appModel.activeWeek {
                        ForEach(week.days) { day in
                            WorkoutDayPlanCard(day: day, isCompleted: appModel.isWorkoutCompleted(day))
                        }
                    } else {
                        EmptyStateView(
                            title: "No active week",
                            subtitle: "Complete onboarding to create your first local training week.",
                            systemImage: "calendar"
                        )
                    }
                }
                .padding(20)
            }
            .navigationTitle("Plan")
            .coachInlineNavigationTitle()
            .background(CoachTheme.background)
        }
    }

    private var planHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(appModel.snapshot.activePlan?.title ?? "Workout Plan")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(CoachTheme.primaryText)
            Text(appModel.snapshot.activePlan?.summary ?? "Generated workouts will appear here.")
                .font(.subheadline)
                .foregroundStyle(CoachTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct WorkoutDayPlanCard: View {
    var day: WorkoutDay
    var isCompleted: Bool

    var body: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Day \(day.dayIndex)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(isCompleted ? CoachTheme.accentMint : CoachTheme.accentBlue)
                        Text(day.title)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(CoachTheme.primaryText)
                    }
                    Spacer()
                    Image(systemName: isCompleted ? "checkmark.seal.fill" : "circle")
                        .foregroundStyle(isCompleted ? CoachTheme.accentMint : CoachTheme.tertiaryText)
                }

                HStack(spacing: 10) {
                    MetricPill(title: "Duration", value: "\(day.estimatedDurationMinutes)m", systemImage: "clock", tint: CoachTheme.accentBlue)
                    MetricPill(title: "Difficulty", value: day.difficulty.rawValue, systemImage: "gauge.with.dots.needle.67percent", tint: CoachTheme.accentGold)
                }

                VStack(spacing: 12) {
                    ForEach(day.exercises) { exercise in
                        NavigationLink {
                            ExerciseDetailView(exercise: exercise)
                        } label: {
                            ExerciseSummaryRow(exercise: exercise)
                        }
                        .buttonStyle(.plain)

                        if exercise.id != day.exercises.last?.id {
                            Divider().overlay(Color.white.opacity(0.08))
                        }
                    }
                }
            }
        }
    }
}
