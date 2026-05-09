import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var step = 0

    private let finalStep = 5

    var body: some View {
        ZStack {
            CoachTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    progressDots
                    stepContent
                    footerButton
                }
                .padding(20)
                .padding(.top, 28)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Apex Coach")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(CoachTheme.primaryText)
                Spacer()
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(CoachTheme.accentMint)
                    .frame(width: 44, height: 44)
                    .background(CoachTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            Text("Build a local-first program that adapts from your training history and runs offline after setup.")
                .font(.subheadline)
                .foregroundStyle(CoachTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0...finalStep, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? CoachTheme.accentMint : Color.white.opacity(0.12))
                    .frame(height: 5)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: step)
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 0:
            profileStep
        case 1:
            scheduleStep
        case 2:
            equipmentStep
        case 3:
            trainingPreferencesStep
        case 4:
            limitationsStep
        default:
            reviewStep
        }
    }

    private var profileStep: some View {
        VStack(spacing: 18) {
            PremiumCard {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "Goals", subtitle: "Select all that apply. Athletic Body is tuned for lean muscle, posture, and conditioning.")
                    TextField("Name", text: $viewModel.name)
                        .padding(14)
                        .background(CoachTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .foregroundStyle(CoachTheme.primaryText)

                    MultiSelectionGrid(items: FitnessGoal.allCases, selected: viewModel.selectedGoals) { item in
                        viewModel.toggleGoal(item)
                    } label: { $0.rawValue }
                }
            }

            PremiumCard {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "Experience", subtitle: "Progression speed stays realistic for your training age.")
                    SelectionGrid(items: ExperienceLevel.allCases, selected: viewModel.experienceLevel) { item in
                        viewModel.experienceLevel = item
                    } label: { $0.rawValue }
                }
            }
        }
    }

    private var scheduleStep: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(title: "Schedule", subtitle: "A week that fits your actual life is the one that gets repeated.")

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Workout days")
                            .foregroundStyle(CoachTheme.primaryText)
                        Spacer()
                        Text("\(viewModel.workoutDaysPerWeek)")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(CoachTheme.accentMint)
                    }
                    Stepper("Days", value: $viewModel.workoutDaysPerWeek, in: 1...7)
                        .labelsHidden()
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Duration")
                        .font(.headline)
                        .foregroundStyle(CoachTheme.primaryText)
                    SelectionGrid(items: WorkoutDurationPreference.allCases, selected: viewModel.durationPreference) { item in
                        viewModel.durationPreference = item
                    } label: { $0.label }
                }
            }
        }
    }

    private var equipmentStep: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(title: "Equipment", subtitle: "The app will only program movements you can do locally.")
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 10)], spacing: 10) {
                    ForEach(EquipmentType.allCases) { item in
                        SelectionChip(title: item.rawValue, isSelected: viewModel.equipment.contains(item)) {
                            viewModel.toggleEquipment(item)
                        }
                    }
                }

                SectionHeader(title: "Muscle Focus", subtitle: "Choose full body or emphasize specific areas.")
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], spacing: 10) {
                    ForEach(MuscleGroup.allCases) { muscle in
                        SelectionChip(title: muscle.rawValue, isSelected: viewModel.targetMuscles.contains(muscle)) {
                            viewModel.toggleMuscle(muscle)
                        }
                    }
                }
            }
        }
    }

    private var trainingPreferencesStep: some View {
        VStack(spacing: 18) {
            PremiumCard {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "Split", subtitle: "This controls how muscles are distributed through the week.")
                    SelectionGrid(items: WorkoutSplit.allCases, selected: viewModel.preferredSplit) { item in
                        viewModel.preferredSplit = item
                    } label: { $0.rawValue }
                }
            }

            PremiumCard {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "Training Style", subtitle: "Timers, reps, and rest will adjust around this.")
                    SelectionGrid(items: TrainingStyle.allCases, selected: viewModel.trainingStyle) { item in
                        viewModel.trainingStyle = item
                    } label: { $0.rawValue }
                }
            }
        }
    }

    private var limitationsStep: some View {
        VStack(spacing: 18) {
            PremiumCard {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "Cardio", subtitle: "Conditioning is added without taking over the strength work.")
                    SelectionGrid(items: CardioPreference.allCases, selected: viewModel.cardioPreference) { item in
                        viewModel.cardioPreference = item
                    } label: { $0.rawValue }
                }
            }

            PremiumCard {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Limitations", subtitle: "Saved locally. Use this for injuries, pain triggers, or movement constraints.")
                    TextEditor(text: $viewModel.injuriesOrLimitations)
                        .frame(minHeight: 120)
                        .scrollContentBackground(.hidden)
                        .padding(10)
                        .background(CoachTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .foregroundStyle(CoachTheme.primaryText)
                }
            }
        }
    }

    private var reviewStep: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(title: "Program Ready", subtitle: "Generation uses local rules now, with a service boundary ready for an AI API later.")

                HStack(spacing: 12) {
                    MetricPill(title: "Primary Goal", value: viewModel.primaryGoal.rawValue, systemImage: "target", tint: CoachTheme.accentMint)
                    MetricPill(title: "Week", value: "\(viewModel.workoutDaysPerWeek)x", systemImage: "calendar", tint: CoachTheme.accentBlue)
                }

                HStack(spacing: 12) {
                    MetricPill(title: "Split", value: viewModel.preferredSplit.rawValue, systemImage: "square.grid.2x2", tint: CoachTheme.accentPurple)
                    MetricPill(title: "Style", value: viewModel.trainingStyle.rawValue, systemImage: "bolt.fill", tint: CoachTheme.accentGold)
                }

                MuscleDiagramView(
                    primaryMuscles: Array(viewModel.targetMuscles),
                    secondaryMuscles: [],
                    side: .front
                )
                .frame(maxHeight: 360)
            }
        }
    }

    private var footerButton: some View {
        HStack(spacing: 12) {
            if step > 0 {
                GlassIconButton(systemImage: "chevron.left", title: "Back") {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                        step -= 1
                    }
                }
            }

            PrimaryCoachButton(
                title: step == finalStep ? "Generate Local Plan" : "Continue",
                systemImage: step == finalStep ? "sparkles" : "arrow.right",
                isLoading: viewModel.isGenerating
            ) {
                if step == finalStep {
                    generatePlan()
                } else {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                        step += 1
                    }
                }
            }
        }
    }

    private func generatePlan() {
        viewModel.isGenerating = true
        let profile = viewModel.makeProfile()
        Task {
            await appModel.completeOnboarding(with: profile)
            viewModel.isGenerating = false
        }
    }
}

private struct SelectionGrid<Item: Identifiable & Hashable>: View {
    var items: [Item]
    var selected: Item
    var action: (Item) -> Void
    var label: (Item) -> String

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 10)], spacing: 10) {
            ForEach(items) { item in
                SelectionChip(title: label(item), isSelected: item == selected) {
                    action(item)
                }
            }
        }
    }
}

private struct MultiSelectionGrid<Item: Identifiable & Hashable>: View {
    var items: [Item]
    var selected: Set<Item>
    var action: (Item) -> Void
    var label: (Item) -> String

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 10)], spacing: 10) {
            ForEach(items) { item in
                SelectionChip(title: label(item), isSelected: selected.contains(item)) {
                    action(item)
                }
            }
        }
    }
}
