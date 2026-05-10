import SwiftUI

struct WorkoutPlanView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @State private var selectedTab = "Exercises"
    @State private var activeWorkout: PlanWorkoutLaunch?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let workout = appModel.todayWorkout {
                        workoutHeader(workout)
                        CoachSegmentedControl(items: ["Exercises", "Details"], selection: $selectedTab)

                        if selectedTab == "Exercises" {
                            exerciseList(for: workout)
                        } else {
                            details(for: workout)
                        }

                        PrimaryCoachButton(title: appModel.hasSavedProgress(for: workout) ? "Resume Workout" : "Start Workout", systemImage: "play.fill") {
                            activeWorkout = PlanWorkoutLaunch(workout: workout, savedProgress: appModel.savedProgress(for: workout))
                        }

                        if appModel.hasSavedProgress(for: workout) {
                            Button {
                                appModel.clearSavedProgress(for: workout)
                                activeWorkout = PlanWorkoutLaunch(workout: workout, savedProgress: nil)
                            } label: {
                                Label("Restart Workout", systemImage: "arrow.counterclockwise")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(CoachTheme.secondaryText)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(CoachTheme.surface.opacity(0.72))
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)
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
                .padding(.bottom, 20)
            }
            .navigationTitle("")
            .coachInlineNavigationTitle()
            .background(CoachTheme.background)
        }
        .coachFullScreenCover(item: $activeWorkout) { launch in
            ActiveWorkoutView(workout: launch.workout, savedProgress: launch.savedProgress)
                .environmentObject(appModel)
        }
    }

    private func workoutHeader(_ workout: WorkoutDay) -> some View {
        HStack {
            GlassIconButton(systemImage: "chevron.left", title: "Back") {}
            Spacer()
            Text(workout.title)
                .font(.headline.weight(.bold))
                .foregroundStyle(CoachTheme.primaryText)
            Spacer()
            GlassIconButton(systemImage: "ellipsis", title: "More") {}
        }
        .padding(.top, 6)
    }

    private func exerciseList(for workout: WorkoutDay) -> some View {
        VStack(spacing: 14) {
            if !workout.warmUpExercises.isEmpty {
                section(title: "Warm Up", exercises: workout.warmUpExercises)
            }

            section(title: "Workout", exercises: workout.mainExercises)

            if !workout.stretchingExercises.isEmpty {
                section(title: "Stretching", exercises: workout.stretchingExercises)
            }
        }
    }

    private func section(title: String, exercises: [Exercise]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(CoachTheme.secondaryText)
                .textCase(.uppercase)

            VStack(spacing: 10) {
                ForEach(exercises) { exercise in
                    NavigationLink {
                        ExerciseDetailView(exercise: exercise)
                    } label: {
                        ExerciseListCard(exercise: exercise)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func details(for workout: WorkoutDay) -> some View {
        VStack(spacing: 12) {
            PremiumCard {
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader(title: "Workout Structure", subtitle: "Auto-flow runs every phase in order.")
                    HStack(spacing: 10) {
                        StatTile(value: "\(workout.warmUpExercises.count)", label: "Warm Up")
                        StatTile(value: "\(workout.mainExercises.count)", label: "Workout")
                        StatTile(value: "\(workout.stretchingExercises.count)", label: "Stretch")
                    }
                }
            }

            PremiumCard {
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader(title: "Muscle Focus", subtitle: workout.muscleFocus.map(\.rawValue).joined(separator: " • "))
                    HStack(spacing: 12) {
                        MuscleDiagramView(primaryMuscles: workout.muscleFocus, secondaryMuscles: workout.exercises.flatMap(\.secondaryMuscles), viewMode: .front)
                        MuscleDiagramView(primaryMuscles: workout.muscleFocus, secondaryMuscles: workout.exercises.flatMap(\.secondaryMuscles), viewMode: .back)
                    }
                    .frame(maxHeight: 300)
                }
            }
        }
    }
}

private struct PlanWorkoutLaunch: Identifiable {
    let id = UUID()
    var workout: WorkoutDay
    var savedProgress: SavedWorkoutProgress?
}

private struct ExerciseListCard: View {
    var exercise: Exercise

    var body: some View {
        HStack(spacing: 14) {
            ExerciseArtworkView(exercise: exercise)
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CoachTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(CoachTheme.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "ellipsis")
                .font(.headline)
                .foregroundStyle(CoachTheme.tertiaryText)
        }
        .padding(12)
        .background(CoachTheme.surface.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(CoachTheme.stroke, lineWidth: 1)
        )
    }

    private var subtitle: String {
        if exercise.phase == .main {
            return "\(exercise.sets) sets x \(exercise.targetReps.label) reps"
        }
        return "\(Int(exercise.workDuration)) sec \(exercise.phase.rawValue.lowercased())"
    }
}
