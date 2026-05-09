import SwiftUI

struct ProgressViewScreen: View {
    @EnvironmentObject private var appModel: AppViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    metricsGrid
                    muscleBreakdown
                    personalRecords
                    workoutHistory
                }
                .padding(20)
            }
            .navigationTitle("Progress")
            .coachInlineNavigationTitle()
            .background(CoachTheme.background)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Performance")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(CoachTheme.primaryText)
            Text("History, volume, consistency, and PRs stay on this device.")
                .font(.subheadline)
                .foregroundStyle(CoachTheme.secondaryText)
        }
    }

    private var metricsGrid: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                MetricPill(title: "Weekly Volume", value: appModel.progressMetrics.weeklyVolume.compactNumber, systemImage: "chart.bar.fill", tint: CoachTheme.accentMint)
                MetricPill(title: "Completed", value: "\(appModel.progressMetrics.completedWorkouts)", systemImage: "checkmark.seal.fill", tint: CoachTheme.accentBlue)
            }
            HStack(spacing: 10) {
                MetricPill(title: "Streak", value: "\(appModel.progressMetrics.currentStreak)d", systemImage: "flame.fill", tint: CoachTheme.accentCoral)
                MetricPill(title: "PRs", value: "\(appModel.snapshot.personalRecords.count)", systemImage: "trophy.fill", tint: CoachTheme.accentGold)
            }
        }
    }

    private var muscleBreakdown: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Muscle Breakdown", subtitle: "Completed set distribution this week.")
                let data = appModel.progressMetrics.muscleBreakdown.sorted { $0.value > $1.value }
                if data.isEmpty {
                    Text("Complete a workout to see muscle distribution.")
                        .font(.subheadline)
                        .foregroundStyle(CoachTheme.secondaryText)
                } else {
                    ForEach(data, id: \.key) { item in
                        MuscleBar(name: item.key.rawValue, value: item.value, maxValue: data.first?.value ?? 1)
                    }
                }
            }
        }
    }

    private var personalRecords: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Personal Records", subtitle: "Best logged result per exercise.")
                if appModel.snapshot.personalRecords.isEmpty {
                    Text("No PRs yet.")
                        .font(.subheadline)
                        .foregroundStyle(CoachTheme.secondaryText)
                } else {
                    ForEach(appModel.snapshot.personalRecords.sorted { $0.achievedAt > $1.achievedAt }.prefix(6)) { record in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.exerciseName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(CoachTheme.primaryText)
                                Text(record.achievedAt, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(CoachTheme.secondaryText)
                            }
                            Spacer()
                            Text("\(record.value.compactNumber) \(record.unit)")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(CoachTheme.accentMint)
                        }
                    }
                }
            }
        }
    }

    private var workoutHistory: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Workout History", subtitle: "Recent completed and partial sessions.")
                if appModel.snapshot.workoutHistory.isEmpty {
                    Text("Your first session will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(CoachTheme.secondaryText)
                } else {
                    ForEach(appModel.snapshot.workoutHistory.sorted { $0.completedAt > $1.completedAt }.prefix(8)) { session in
                        HStack {
                            Image(systemName: session.wasCompleted ? "checkmark.circle.fill" : "minus.circle.fill")
                                .foregroundStyle(session.wasCompleted ? CoachTheme.accentMint : CoachTheme.accentGold)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(CoachTheme.primaryText)
                                Text("\(session.completedAt.formatted(date: .abbreviated, time: .shortened)) • \(session.durationSeconds.clockString)")
                                    .font(.caption)
                                    .foregroundStyle(CoachTheme.secondaryText)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

private struct MuscleBar: View {
    var name: String
    var value: Int
    var maxValue: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CoachTheme.primaryText)
                Spacer()
                Text("\(value) sets")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CoachTheme.secondaryText)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.09))
                    Capsule()
                        .fill(CoachTheme.accentGradient)
                        .frame(width: proxy.size.width * CGFloat(Double(value) / Double(max(maxValue, 1))))
                }
            }
            .frame(height: 8)
        }
    }
}
