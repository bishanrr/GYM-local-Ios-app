import SwiftUI

struct ExerciseDetailView: View {
    var exercise: Exercise
    @State private var selectedTab = "Overview"

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    CoachSegmentedControl(items: ["Overview", "History", "Tips"], selection: $selectedTab)

                    switch selectedTab {
                    case "History":
                        history
                    case "Tips":
                        tips
                    default:
                        overview
                    }
                }
                .padding(20)
                .padding(.bottom, 90)
            }

            PrimaryCoachButton(title: "Add to Workout", systemImage: "plus") {}
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .background(CoachTheme.background.opacity(0.94))
        }
        .background(CoachTheme.background)
        .navigationTitle("")
        .coachInlineNavigationTitle()
    }

    private var header: some View {
        HStack {
            Text(exercise.name)
                .font(.headline.weight(.bold))
                .foregroundStyle(CoachTheme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
            Spacer()
            Image(systemName: "heart")
                .font(.title3.weight(.semibold))
                .foregroundStyle(CoachTheme.primaryText)
        }
        .padding(.top, 4)
    }

    private var overview: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 16) {
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
            .frame(maxHeight: 310)

            muscleList(title: "Primary Muscles", muscles: exercise.primaryMuscles, color: CoachTheme.muscle)
            muscleList(title: "Secondary Muscles", muscles: exercise.secondaryMuscles, color: Color.white.opacity(0.42))
            coachingNote
            prescription
        }
    }

    private var history: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Exercise History", subtitle: "Local performance history will appear here after completed sessions.")
                HStack(spacing: 10) {
                    StatTile(value: "\(exercise.sets)", label: "Sets")
                    StatTile(value: exercise.targetReps.label, label: "Reps")
                    StatTile(value: "\(Int(exercise.restDuration))s", label: "Rest")
                }
            }
        }
    }

    private var tips: some View {
        VStack(spacing: 14) {
            detailList(title: "Coach Tips", items: exercise.tips, systemImage: "sparkles")
            detailList(title: "Safety Notes", items: exercise.safetyNotes, systemImage: "shield.lefthalf.filled")
            detailList(title: "Instructions", items: exercise.instructions, systemImage: "list.number")
        }
    }

    private func muscleList(title: String, muscles: [MuscleGroup], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(CoachTheme.primaryText)

            ForEach(muscles.isEmpty ? [.fullBody] : muscles, id: \.self) { muscle in
                HStack(spacing: 10) {
                    Circle()
                        .fill(color)
                        .frame(width: 10, height: 10)
                    Text(displayName(for: muscle))
                        .font(.subheadline)
                        .foregroundStyle(CoachTheme.secondaryText)
                }
            }
        }
    }

    private var coachingNote: some View {
        PremiumCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundStyle(CoachTheme.accentBlue)
                Text(exercise.tips.first ?? "Move with control and keep the target muscles doing the work.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(CoachTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var prescription: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Prescription", subtitle: exercise.phase.rawValue)
                HStack(spacing: 10) {
                    StatTile(value: "\(exercise.sets)", label: "Sets")
                    StatTile(value: exercise.targetReps.label, label: "Reps")
                    StatTile(value: exercise.restDuration.clockString, label: "Rest")
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
                            .fill(CoachTheme.accentBlue)
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

    private func displayName(for muscle: MuscleGroup) -> String {
        switch muscle {
        case .chest:
            return "Chest (Pectorals)"
        case .shoulders:
            return "Anterior Shoulders (Deltoids)"
        case .triceps:
            return "Triceps"
        case .back:
            return "Back (Lats + Upper Back)"
        case .biceps:
            return "Biceps"
        case .core:
            return "Core"
        case .quads:
            return "Quads"
        case .hamstrings:
            return "Hamstrings"
        case .glutes:
            return "Glutes"
        case .calves:
            return "Calves"
        case .fullBody:
            return "Full Body"
        }
    }
}
