import SwiftUI

struct WorkoutPlanView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @State private var selectedTab = "Exercises"
    @State private var activeWorkout: PlanWorkoutLaunch?
    @State private var selectedWeekdayIndex: Int?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if !appModel.weeklyDayStates.isEmpty {
                        planHeader
                        ScheduleCalendarView(
                            states: appModel.weeklyDayStates,
                            selectedDayIndex: selectedState?.weekdayIndex
                        ) { state in
                            selectedWeekdayIndex = state.weekdayIndex
                        }
                        WeeklyWorkoutScheduleView(
                            states: appModel.weeklyDayStates,
                            selectedDayIndex: selectedState?.weekdayIndex
                        ) { state in
                            selectedWeekdayIndex = state.weekdayIndex
                        }

                        if let state = selectedState {
                            selectedDayDetails(for: state)
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
        .onAppear {
            selectedWeekdayIndex = selectedState?.weekdayIndex
        }
        .coachFullScreenCover(item: $activeWorkout) { launch in
            ActiveWorkoutView(workout: launch.workout, savedProgress: launch.savedProgress)
                .environmentObject(appModel)
        }
    }

    private var selectedState: WeekdayWorkoutState? {
        let states = appModel.weeklyDayStates
        if let selectedWeekdayIndex,
           let state = states.first(where: { $0.weekdayIndex == selectedWeekdayIndex }) {
            return state
        }
        return appModel.suggestedWeekdayState ?? states.first
    }

    private var planHeader: some View {
        HStack {
            GlassIconButton(systemImage: "chevron.left", title: "Back") {}
            Spacer()
            Text("Workout Plan")
                .font(.headline.weight(.bold))
                .foregroundStyle(CoachTheme.primaryText)
            Spacer()
            GlassIconButton(systemImage: "ellipsis", title: "More") {}
        }
        .padding(.top, 6)
    }

    @ViewBuilder
    private func selectedDayDetails(for state: WeekdayWorkoutState) -> some View {
        if let workout = state.workout {
            workoutDetail(for: workout, state: state)
        } else {
            restDayDetail(for: state)
        }
    }

    private func workoutDetail(for workout: WorkoutDay, state: WeekdayWorkoutState) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SelectedWorkoutHeader(workout: workout, state: state)

            CoachSegmentedControl(items: ["Exercises", "Details", "Extras"], selection: $selectedTab)

            if selectedTab == "Exercises" {
                exerciseList(for: workout)
            } else if selectedTab == "Details" {
                details(for: workout)
            } else {
                cardioExtras(for: workout, state: state)
            }

            if appModel.canStartWorkout(state) {
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
                Text(state.status == .completed ? "Completed locally" : "Missed workout")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(statusColor(for: state.status))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(statusColor(for: state.status).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    private func restDayDetail(for state: WeekdayWorkoutState) -> some View {
        PremiumCard {
            HStack(spacing: 14) {
                Image(systemName: "moon.stars.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CoachTheme.accentMint)
                    .frame(width: 48, height: 48)
                    .background(CoachTheme.surfaceStrong)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text("Rest Day")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(CoachTheme.primaryText)
                    Text("\(weekdayName(for: state.date)) is planned for recovery.")
                        .font(.subheadline)
                        .foregroundStyle(CoachTheme.secondaryText)
                }

                Spacer()
            }
        }
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

    private func cardioExtras(for workout: WorkoutDay, state: WeekdayWorkoutState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Cardio Extras",
                subtitle: "Add a timed finisher to \(weekdayName(for: state.date))."
            )

            VStack(spacing: 10) {
                ForEach(CardioExtraOption.library) { option in
                    CardioExtraCard(
                        option: option,
                        isAdded: workout.exercises.contains { $0.name == option.exerciseName },
                        canAdd: appModel.canStartWorkout(state)
                    ) {
                        appModel.addExtraExercise(option.exercise(), to: workout)
                    }
                }
            }
        }
    }

    private func statusColor(for status: WeekdayWorkoutStatus) -> Color {
        switch status {
        case .completed:
            return CoachTheme.accentMint
        case .inProgress:
            return CoachTheme.accentPurple
        case .missed, .incomplete:
            return CoachTheme.accentCoral
        case .upcoming:
            return CoachTheme.accentGold
        case .available:
            return CoachTheme.accentBlue
        case .rest:
            return CoachTheme.tertiaryText
        }
    }

    private func weekdayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

private struct PlanWorkoutLaunch: Identifiable {
    let id = UUID()
    var workout: WorkoutDay
    var savedProgress: SavedWorkoutProgress?
}

private struct ScheduleCalendarView: View {
    var states: [WeekdayWorkoutState]
    var selectedDayIndex: Int?
    var onSelect: (WeekdayWorkoutState) -> Void

    private var calendar: Calendar { Calendar.current }
    private var monthDate: Date { states.first?.date ?? Date() }

    var body: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionHeader(title: monthTitle, subtitle: "Scheduled, completed, in progress, and missed workouts")
                    Spacer()
                }

                HStack(spacing: 6) {
                    ForEach(weekdaySymbols, id: \.self) { symbol in
                        Text(symbol)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(CoachTheme.tertiaryText)
                            .frame(maxWidth: .infinity)
                    }
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                    ForEach(calendarDays, id: \.self) { date in
                        if let state = state(for: date) {
                            Button {
                                onSelect(state)
                            } label: {
                                CalendarDayCell(
                                    day: calendar.component(.day, from: date),
                                    isCurrentMonth: calendar.isDate(date, equalTo: monthDate, toGranularity: .month),
                                    isSelected: selectedDayIndex == state.weekdayIndex,
                                    status: state.status
                                )
                            }
                            .buttonStyle(.plain)
                        } else {
                            CalendarDayCell(
                                day: calendar.component(.day, from: date),
                                isCurrentMonth: calendar.isDate(date, equalTo: monthDate, toGranularity: .month),
                                isSelected: false,
                                status: nil
                            )
                        }
                    }
                }

                HStack(spacing: 12) {
                    LegendDot(title: "Planned", color: CoachTheme.accentGold)
                    LegendDot(title: "Resume", color: CoachTheme.accentPurple)
                    LegendDot(title: "Done", color: CoachTheme.accentMint)
                    LegendDot(title: "Missed", color: CoachTheme.accentCoral)
                }
            }
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: monthDate)
    }

    private var weekdaySymbols: [String] {
        calendar.veryShortStandaloneWeekdaySymbols
    }

    private var calendarDays: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthDate),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        return (0..<42).compactMap {
            calendar.date(byAdding: .day, value: $0, to: firstWeek.start)
        }
    }

    private func state(for date: Date) -> WeekdayWorkoutState? {
        states.first { calendar.isDate($0.date, inSameDayAs: date) }
    }
}

private struct CalendarDayCell: View {
    var day: Int
    var isCurrentMonth: Bool
    var isSelected: Bool
    var status: WeekdayWorkoutStatus?

    var body: some View {
        VStack(spacing: 5) {
            Text("\(day)")
                .font(.caption.weight(.bold))
                .foregroundStyle(isCurrentMonth ? CoachTheme.primaryText : CoachTheme.tertiaryText.opacity(0.6))
                .monospacedDigit()

            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
                .opacity(status == nil || status == .rest ? 0.28 : 1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? statusColor.opacity(0.22) : CoachTheme.surfaceStrong.opacity(status == nil ? 0.18 : 0.52))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSelected ? statusColor.opacity(0.7) : CoachTheme.stroke, lineWidth: isSelected ? 1.4 : 1)
        )
    }

    private var statusColor: Color {
        guard let status else { return Color.white.opacity(0.18) }
        switch status {
        case .completed:
            return CoachTheme.accentMint
        case .inProgress:
            return CoachTheme.accentPurple
        case .missed, .incomplete:
            return CoachTheme.accentCoral
        case .upcoming:
            return CoachTheme.accentGold
        case .available:
            return CoachTheme.accentBlue
        case .rest:
            return Color.white.opacity(0.24)
        }
    }
}

private struct LegendDot: View {
    var title: String
    var color: Color

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CoachTheme.secondaryText)
        }
    }
}

private struct WeeklyWorkoutScheduleView: View {
    var states: [WeekdayWorkoutState]
    var selectedDayIndex: Int?
    var onSelect: (WeekdayWorkoutState) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Schedule")
                .font(.headline.weight(.semibold))
                .foregroundStyle(CoachTheme.primaryText)

            VStack(spacing: 10) {
                ForEach(states) { state in
                    Button {
                        onSelect(state)
                    } label: {
                        ScheduleDayRow(state: state, isSelected: selectedDayIndex == state.weekdayIndex)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct ScheduleDayRow: View {
    var state: WeekdayWorkoutState
    var isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 3) {
                Text(weekdayShort)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(CoachTheme.secondaryText)
                Text(dayNumber)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(CoachTheme.primaryText)
                    .monospacedDigit()
            }
            .frame(width: 46, height: 54)
            .background(statusColor.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(state.workout?.title ?? "Rest Day")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CoachTheme.primaryText)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CoachTheme.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            Text(statusTitle)
                .font(.caption2.weight(.bold))
                .foregroundStyle(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(statusColor.opacity(0.14))
                .clipShape(Capsule())
        }
        .padding(12)
        .background(CoachTheme.surface.opacity(isSelected ? 1 : 0.78))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSelected ? statusColor.opacity(0.62) : CoachTheme.stroke, lineWidth: isSelected ? 1.4 : 1)
        )
    }

    private var weekdayShort: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: state.date)
    }

    private var dayNumber: String {
        "\(Calendar.current.component(.day, from: state.date))"
    }

    private var subtitle: String {
        guard let workout = state.workout else {
            return "Recovery planned"
        }
        return "\(workout.estimatedDurationMinutes) min • \(workout.muscleFocus.prefix(3).map(\.rawValue).joined(separator: " • "))"
    }

    private var statusTitle: String {
        switch state.status {
        case .completed:
            return "Done"
        case .inProgress:
            return "Resume"
        case .missed:
            return "Missed"
        case .incomplete:
            return "Retry"
        case .upcoming:
            return "Planned"
        case .available:
            return "Due"
        case .rest:
            return "Rest"
        }
    }

    private var statusColor: Color {
        switch state.status {
        case .completed:
            return CoachTheme.accentMint
        case .inProgress:
            return CoachTheme.accentPurple
        case .missed, .incomplete:
            return CoachTheme.accentCoral
        case .upcoming:
            return CoachTheme.accentGold
        case .available:
            return CoachTheme.accentBlue
        case .rest:
            return CoachTheme.tertiaryText
        }
    }
}

private struct SelectedWorkoutHeader: View {
    var workout: WorkoutDay
    var state: WeekdayWorkoutState

    var body: some View {
        PremiumCard {
            HStack(spacing: 14) {
                HeroMuscleFigure(
                    primaryMuscles: workout.muscleFocus,
                    secondaryMuscles: workout.exercises.flatMap(\.secondaryMuscles),
                    pose: .standing
                )
                .frame(width: 74, height: 92)

                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 8) {
                        Text(weekdayName)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(CoachTheme.secondaryText)
                        Text(statusTitle)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(statusColor)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(statusColor.opacity(0.14))
                            .clipShape(Capsule())
                    }

                    Text(workout.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(CoachTheme.primaryText)
                        .lineLimit(2)

                    Text("\(workout.estimatedDurationMinutes) min • \(workout.exercises.count) movements")
                        .font(.subheadline)
                        .foregroundStyle(CoachTheme.secondaryText)
                }

                Spacer()
            }
        }
    }

    private var weekdayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: state.date)
    }

    private var statusTitle: String {
        switch state.status {
        case .completed:
            return "Completed"
        case .inProgress:
            return "In Progress"
        case .missed:
            return "Missed"
        case .incomplete:
            return "Incomplete"
        case .upcoming:
            return "Planned"
        case .available:
            return "Scheduled"
        case .rest:
            return "Rest"
        }
    }

    private var statusColor: Color {
        switch state.status {
        case .completed:
            return CoachTheme.accentMint
        case .inProgress:
            return CoachTheme.accentPurple
        case .missed, .incomplete:
            return CoachTheme.accentCoral
        case .upcoming:
            return CoachTheme.accentGold
        case .available:
            return CoachTheme.accentBlue
        case .rest:
            return CoachTheme.tertiaryText
        }
    }
}

private struct CardioExtraOption: Identifiable {
    var title: String
    var minutes: Int
    var subtitle: String
    var systemImage: String
    var primaryMuscles: [MuscleGroup]
    var secondaryMuscles: [MuscleGroup]
    var equipment: [EquipmentType]
    var difficulty: DifficultyLevel

    var id: String { exerciseName }
    var exerciseName: String { "\(title) \(minutes) min" }

    static let library: [CardioExtraOption] = [
        CardioExtraOption(
            title: "Incline Walk",
            minutes: 20,
            subtitle: "Low impact fat-loss finisher",
            systemImage: "figure.walk",
            primaryMuscles: [.calves, .glutes],
            secondaryMuscles: [.quads, .core],
            equipment: [.bodyweight, .machines, .fullGym],
            difficulty: .easy
        ),
        CardioExtraOption(
            title: "Zone 2 Bike",
            minutes: 30,
            subtitle: "Steady endurance builder",
            systemImage: "figure.indoor.cycle",
            primaryMuscles: [.quads, .calves],
            secondaryMuscles: [.glutes, .core],
            equipment: [.machines, .fullGym],
            difficulty: .moderate
        ),
        CardioExtraOption(
            title: "Row Intervals",
            minutes: 20,
            subtitle: "Full-body conditioning bursts",
            systemImage: "figure.rower",
            primaryMuscles: [.back, .quads],
            secondaryMuscles: [.core, .biceps, .glutes],
            equipment: [.machines, .fullGym],
            difficulty: .hard
        ),
        CardioExtraOption(
            title: "Elliptical Cruise",
            minutes: 45,
            subtitle: "Joint-friendly aerobic work",
            systemImage: "figure.elliptical",
            primaryMuscles: [.quads, .glutes],
            secondaryMuscles: [.calves, .core],
            equipment: [.machines, .fullGym],
            difficulty: .moderate
        ),
        CardioExtraOption(
            title: "Treadmill Run",
            minutes: 30,
            subtitle: "Classic conditioning session",
            systemImage: "figure.run",
            primaryMuscles: [.quads, .hamstrings, .calves],
            secondaryMuscles: [.glutes, .core],
            equipment: [.bodyweight, .machines, .fullGym],
            difficulty: .hard
        ),
        CardioExtraOption(
            title: "Jump Rope Intervals",
            minutes: 20,
            subtitle: "Fast footwork and cardio pop",
            systemImage: "figure.jumprope",
            primaryMuscles: [.calves, .core],
            secondaryMuscles: [.shoulders, .quads],
            equipment: [.bodyweight],
            difficulty: .hard
        )
    ]

    func exercise() -> Exercise {
        Exercise(
            name: exerciseName,
            primaryMuscles: primaryMuscles,
            secondaryMuscles: secondaryMuscles,
            instructions: [
                "Set a sustainable pace for the full timed block.",
                "Keep breathing controlled and posture tall.",
                "Finish with two easy minutes if your heart rate is high."
            ],
            tips: [
                "Treat this as an add-on, not a max effort test.",
                "Stay smooth enough that form does not break down."
            ],
            safetyNotes: [
                "Stop if you feel chest pain, dizziness, or sharp joint pain.",
                "Reduce speed or resistance if you cannot control breathing."
            ],
            sets: 1,
            targetReps: RepRange(lowerBound: 1, upperBound: 1),
            suggestedWeight: nil,
            restDuration: 0,
            workDuration: TimeInterval(minutes * 60),
            equipment: equipment,
            difficulty: difficulty,
            phase: .main
        )
    }
}

private struct CardioExtraCard: View {
    var option: CardioExtraOption
    var isAdded: Bool
    var canAdd: Bool
    var onAdd: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(CoachTheme.accentBlue.opacity(0.14))
                Image(systemName: option.systemImage)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CoachTheme.accentBlue)
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 5) {
                Text(option.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CoachTheme.primaryText)
                    .lineLimit(1)
                Text("\(option.minutes) min • \(option.subtitle)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CoachTheme.secondaryText)
                    .lineLimit(2)
            }

            Spacer()

            Button {
                onAdd()
            } label: {
                Text(isAdded ? "Added" : "Add")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isAdded ? CoachTheme.accentMint : .white)
                    .frame(width: 58, height: 34)
                    .background(isAdded ? CoachTheme.accentMint.opacity(0.12) : CoachTheme.accentBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isAdded || !canAdd)
            .opacity(canAdd ? 1 : 0.44)
        }
        .padding(12)
        .background(CoachTheme.surface.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isAdded ? CoachTheme.accentMint.opacity(0.35) : CoachTheme.stroke, lineWidth: 1)
        )
    }
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
