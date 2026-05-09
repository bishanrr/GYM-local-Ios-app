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
            ExerciseRemoteImagePanel(exercise: exercise)

            HStack(spacing: 16) {
                MuscleDiagramView(
                    primaryMuscles: exercise.primaryMuscles,
                    secondaryMuscles: exercise.secondaryMuscles,
                    viewMode: .front
                )
                MuscleDiagramView(
                    primaryMuscles: exercise.primaryMuscles,
                    secondaryMuscles: exercise.secondaryMuscles,
                    viewMode: .back
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

private struct ExerciseRemoteImagePanel: View {
    var exercise: Exercise
    @StateObject private var viewModel = ExerciseImageViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .bottomLeading) {
                if let image = viewModel.image {
                    PlatformExerciseImage(image: image)
                        .frame(maxWidth: .infinity)
                        .frame(height: 260)
                        .clipped()
                } else if viewModel.isLoading {
                    ExerciseImageShimmer()
                        .frame(height: 260)
                } else {
                    MuscleDiagramView(
                        primaryMuscles: exercise.primaryMuscles,
                        secondaryMuscles: exercise.secondaryMuscles,
                        viewMode: .front
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                }

                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.72)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 5) {
                    Text(viewModel.remoteExercise?.name ?? exercise.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(CoachTheme.primaryText)
                        .lineLimit(1)

                    Text(panelSubtitle)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(CoachTheme.secondaryText)
                        .lineLimit(2)
                }
                .padding(14)
            }
            .background(CoachTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(CoachTheme.stroke, lineWidth: 1)
            )

            if let remoteExercise = viewModel.remoteExercise, !remoteExercise.description.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("wger Instructions")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(CoachTheme.accentBlue)
                    Text(remoteExercise.description)
                        .font(.caption)
                        .foregroundStyle(CoachTheme.secondaryText)
                        .lineLimit(5)
                    if !remoteExercise.equipment.isEmpty {
                        Text("Equipment: \(remoteExercise.equipment.prefix(3).joined(separator: ", "))")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CoachTheme.tertiaryText)
                            .lineLimit(1)
                    }
                }
                .padding(12)
                .background(CoachTheme.surface.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .task(id: exercise.id) {
            await viewModel.load(for: exercise)
        }
    }

    private var panelSubtitle: String {
        if let remote = viewModel.remoteExercise {
            let muscles = (remote.primaryMuscles + remote.secondaryMuscles).prefix(3).joined(separator: " • ")
            if !muscles.isEmpty {
                return muscles
            }
            return remote.equipment.prefix(2).joined(separator: " • ")
        }

        if viewModel.isLoading {
            return "Searching wger image cache"
        }

        return "Local muscle diagram fallback"
    }
}

private struct PlatformExerciseImage: View {
    var image: UIImage

    var body: some View {
        #if canImport(UIKit)
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .padding(12)
        #elseif canImport(AppKit)
        Image(nsImage: image)
            .resizable()
            .scaledToFit()
            .padding(12)
        #else
        EmptyView()
        #endif
    }
}

private struct ExerciseImageShimmer: View {
    @State private var offset: CGFloat = -1

    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(CoachTheme.surfaceStrong)
            .overlay {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.02),
                        Color.white.opacity(0.16),
                        Color.white.opacity(0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .rotationEffect(.degrees(18))
                .offset(x: offset * 280)
            }
            .overlay {
                VStack(spacing: 12) {
                    ProgressRing(progress: 0.64, lineWidth: 8)
                        .frame(width: 74, height: 74)
                    Text("Loading exercise image")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CoachTheme.secondaryText)
                }
            }
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.25).repeatForever(autoreverses: false)) {
                    offset = 1
                }
            }
    }
}
