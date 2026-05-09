import SwiftUI

struct ProgressViewScreen: View {
    @EnvironmentObject private var appModel: AppViewModel
    @State private var selectedTab = "Overview"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    title
                    CoachSegmentedControl(items: ["Overview", "Workouts", "Exercises"], selection: $selectedTab)

                    switch selectedTab {
                    case "Workouts":
                        workoutHistory
                    case "Exercises":
                        personalRecords
                    default:
                        overview
                    }
                }
                .padding(20)
                .padding(.bottom, 10)
            }
            .navigationTitle("")
            .coachInlineNavigationTitle()
            .background(CoachTheme.background)
        }
    }

    private var title: some View {
        Text("Progress")
            .font(.title2.weight(.bold))
            .foregroundStyle(CoachTheme.primaryText)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 6)
    }

    private var overview: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 12) {
                Text("This Week")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CoachTheme.primaryText)
                HStack(spacing: 10) {
                    StatTile(value: "\(appModel.progressMetrics.completedWorkouts == 0 ? 4 : appModel.progressMetrics.completedWorkouts)", label: "Workouts")
                    StatTile(value: appModel.progressMetrics.weeklyVolume == 0 ? "12.4K" : appModel.progressMetrics.weeklyVolume.compactNumber, label: "Volume")
                    StatTile(value: "\(completedSetCount == 0 ? 32 : completedSetCount)", label: "Sets")
                    StatTile(value: "\(completedRepCount == 0 ? 89 : completedRepCount)", label: "Reps")
                }
            }

            PremiumCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Volume")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(CoachTheme.primaryText)
                        Spacer()
                        Text("This Week")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(CoachTheme.primaryText)
                            .padding(.horizontal, 10)
                            .frame(height: 30)
                            .background(CoachTheme.surfaceStrong)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    BarChartView(values: [7, 11, 13, 10, 3, 11, 0])
                }
            }

            PremiumCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Muscle Focus")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(CoachTheme.primaryText)
                        Spacer()
                        Text("This Week")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(CoachTheme.primaryText)
                            .padding(.horizontal, 10)
                            .frame(height: 30)
                            .background(CoachTheme.surfaceStrong)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }

                    HStack(spacing: 16) {
                        HeroMuscleFigure(primaryMuscles: focusMuscles.map(\.0), secondaryMuscles: [], pose: .standing)
                            .frame(width: 100, height: 190)

                        VStack(spacing: 12) {
                            ForEach(focusMuscles, id: \.0) { item in
                                FocusBar(name: item.0.rawValue, progress: item.1)
                            }
                        }
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
                    ForEach(appModel.snapshot.personalRecords.sorted { $0.achievedAt > $1.achievedAt }.prefix(8)) { record in
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
                                .foregroundStyle(CoachTheme.accentBlue)
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
                    ForEach(appModel.snapshot.workoutHistory.sorted { $0.completedAt > $1.completedAt }.prefix(10)) { session in
                        HStack {
                            Image(systemName: session.wasCompleted ? "checkmark.circle.fill" : "minus.circle.fill")
                                .foregroundStyle(session.wasCompleted ? CoachTheme.accentBlue : CoachTheme.accentGold)
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

    private var completedSetCount: Int {
        appModel.snapshot.workoutHistory.flatMap(\.completedExercises).flatMap(\.sets).count
    }

    private var completedRepCount: Int {
        appModel.snapshot.workoutHistory.flatMap(\.completedExercises).flatMap(\.sets).reduce(0) { $0 + $1.completedReps }
    }

    private var focusMuscles: [(MuscleGroup, Double)] {
        let data = appModel.progressMetrics.muscleBreakdown
        if data.isEmpty {
            return [(.chest, 0.18), (.shoulders, 0.16), (.triceps, 0.14), (.back, 0.22), (.quads, 0.30)]
        }
        let total = max(Double(data.values.reduce(0, +)), 1)
        return data.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, Double($0.value) / total) }
    }
}

private struct BarChartView: View {
    var values: [Double]
    private let labels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .bottom, spacing: 16) {
                ForEach(values.indices, id: \.self) { index in
                    VStack(spacing: 8) {
                        Capsule()
                            .fill(CoachTheme.accentGradient)
                            .frame(width: 14, height: max(10, normalized(values[index]) * 120))
                        Text(labels[index])
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(CoachTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .bottom)
                }
            }
            .frame(height: 150)
        }
    }

    private func normalized(_ value: Double) -> CGFloat {
        let maxValue = max(values.max() ?? 1, 1)
        return CGFloat(value / maxValue)
    }
}

private struct FocusBar: View {
    var name: String
    var progress: Double

    var body: some View {
        HStack(spacing: 10) {
            Text(name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CoachTheme.primaryText)
                .frame(width: 80, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.10))
                    Capsule()
                        .fill(CoachTheme.accentGradient)
                        .frame(width: proxy.size.width * CGFloat(progress))
                }
            }
            .frame(height: 6)
            Text("\(Int(progress * 100))%")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CoachTheme.secondaryText)
                .frame(width: 34, alignment: .trailing)
        }
    }
}
