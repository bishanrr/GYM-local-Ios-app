import SwiftUI

struct ExerciseDetailView: View {
    var exercise: Exercise

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                titleBlock

                HStack(alignment: .top, spacing: 12) {
                    MuscleDiagramView(
                        primaryMuscles: exercise.primaryMuscles,
                        secondaryMuscles: exercise.secondaryMuscles,
                        side: .front
                    )
                    MuscleDiagramView(
                        primaryMuscles: exercise.primaryMuscles,
                        secondaryMuscles: exercise.secondaryMuscles,
                        side: .back
                    )
                }
                .frame(maxHeight: 360)

                prescription
                detailList(title: "Instructions", items: exercise.instructions, systemImage: "list.number")
                detailList(title: "Coach Tips", items: exercise.tips, systemImage: "sparkles")
                detailList(title: "Safety Notes", items: exercise.safetyNotes, systemImage: "shield.lefthalf.filled")
            }
            .padding(20)
        }
        .background(CoachTheme.background)
        .navigationTitle(exercise.name)
        .coachInlineNavigationTitle()
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(exercise.name)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(CoachTheme.primaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.74)
            Text((exercise.primaryMuscles + exercise.secondaryMuscles).map(\.rawValue).joined(separator: " • "))
                .font(.subheadline)
                .foregroundStyle(CoachTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var prescription: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Prescription", subtitle: "Auto-flow uses these timers during the session.")
                HStack(spacing: 10) {
                    MetricPill(title: "Sets", value: "\(exercise.sets)", systemImage: "square.stack.3d.up.fill", tint: CoachTheme.accentPurple)
                    MetricPill(title: "Reps", value: exercise.targetReps.label, systemImage: "repeat", tint: CoachTheme.accentMint)
                }
                HStack(spacing: 10) {
                    MetricPill(title: "Work", value: exercise.workDuration.clockString, systemImage: "stopwatch.fill", tint: CoachTheme.accentBlue)
                    MetricPill(title: "Rest", value: exercise.restDuration.clockString, systemImage: "pause.fill", tint: CoachTheme.accentGold)
                }
            }
        }
    }

    private func detailList(title: String, items: [String], systemImage: String) -> some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 12) {
                Label(title, systemImage: systemImage)
                    .font(.headline)
                    .foregroundStyle(CoachTheme.primaryText)

                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(CoachTheme.accentMint)
                            .frame(width: 6, height: 6)
                            .padding(.top, 7)
                        Text(item)
                            .font(.subheadline)
                            .foregroundStyle(CoachTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}
