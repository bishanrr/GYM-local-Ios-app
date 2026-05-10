import SwiftUI
import UniformTypeIdentifiers

struct WorkoutPlanView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @State private var selectedTab = "Exercises"
    @State private var activeWorkout: PlanWorkoutLaunch?
    @State private var selectedDayID: WeekdayWorkoutState.ID?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if !appModel.trainingBlockDayStates.isEmpty {
                        planHeader
                        ScheduleCalendarView(
                            states: appModel.trainingBlockDayStates,
                            selectedDayID: selectedState?.id
                        ) { state in
                            selectedDayID = state.id
                        } onMove: { workout, targetState in
                            appModel.moveWorkout(workout, toWeekdayIndex: targetState.weekdayIndex)
                            selectedDayID = targetState.id
                        }
                        WeeklyWorkoutScheduleView(
                            states: appModel.trainingBlockDayStates,
                            selectedDayID: selectedState?.id
                        ) { state in
                            selectedDayID = state.id
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
            selectedDayID = selectedState?.id
        }
        .coachFullScreenCover(item: $activeWorkout) { launch in
            ActiveWorkoutView(workout: launch.workout, savedProgress: launch.savedProgress)
                .environmentObject(appModel)
        }
    }

    private var selectedState: WeekdayWorkoutState? {
        let states = appModel.trainingBlockDayStates
        if let selectedDayID,
           let state = states.first(where: { $0.id == selectedDayID }) {
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
            moveWorkoutSection(for: workout, state: state)

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
        VStack(alignment: .leading, spacing: 16) {
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
                        Text("\(weekdayName(for: state.date)) is planned for recovery. You can still add a light cardio extra.")
                            .font(.subheadline)
                            .foregroundStyle(CoachTheme.secondaryText)
                    }

                    Spacer()
                }
            }

            moveWorkoutHereSection(for: state)
            cardioExtras(for: nil, state: state)
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

    private func moveWorkoutSection(for workout: WorkoutDay, state: WeekdayWorkoutState) -> some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(
                    title: "Move Workout",
                    subtitle: "Shift or swap this session within week \(state.weekNumber)."
                )

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    ForEach(states(inWeek: state.weekNumber)) { targetState in
                        MoveDayButton(
                            state: targetState,
                            isCurrentDay: targetState.weekdayIndex == state.weekdayIndex,
                            canMove: canMoveWorkout(from: state, to: targetState)
                        ) {
                            appModel.moveWorkout(workout, toWeekdayIndex: targetState.weekdayIndex)
                            selectedDayID = targetState.id
                        }
                    }
                }
            }
        }
    }

    private func moveWorkoutHereSection(for targetState: WeekdayWorkoutState) -> some View {
        let movableWorkouts = states(inWeek: targetState.weekNumber)
            .filter { sourceState in
                sourceState.workout != nil && canMoveWorkout(from: sourceState, to: targetState)
            }

        guard !movableWorkouts.isEmpty else {
            return AnyView(EmptyView())
        }

        return AnyView(
            PremiumCard {
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader(
                        title: "Move Here",
                        subtitle: "Place a workout on \(weekdayName(for: targetState.date))."
                    )

                    VStack(spacing: 10) {
                        ForEach(movableWorkouts) { sourceState in
                            MoveWorkoutHereRow(sourceState: sourceState) {
                                if let workout = sourceState.workout {
                                    appModel.moveWorkout(workout, toWeekdayIndex: targetState.weekdayIndex)
                                    selectedDayID = targetState.id
                                }
                            }
                        }
                    }
                }
            }
        )
    }

    private func cardioExtras(for workout: WorkoutDay?, state: WeekdayWorkoutState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Cardio Extras",
                subtitle: "Add a timed finisher to \(weekdayName(for: state.date))."
            )

            VStack(spacing: 10) {
                ForEach(CardioExtraOption.library) { option in
                    CardioExtraCard(
                        option: option,
                        isAdded: workout?.exercises.contains { $0.name == option.exerciseName } ?? false,
                        canAdd: canAddExtra(to: state)
                    ) {
                        appModel.addExtraExercise(option.exercise(), to: state)
                    }
                }
            }
        }
    }

    private func canAddExtra(to state: WeekdayWorkoutState) -> Bool {
        Date() < state.deadline && state.status != .completed && state.status != .missed
    }

    private func states(inWeek weekNumber: Int) -> [WeekdayWorkoutState] {
        appModel.trainingBlockDayStates
            .filter { $0.weekNumber == weekNumber }
            .sorted { $0.weekdayIndex < $1.weekdayIndex }
    }

    private func canMoveWorkout(from sourceState: WeekdayWorkoutState, to targetState: WeekdayWorkoutState) -> Bool {
        guard sourceState.weekNumber == targetState.weekNumber,
              sourceState.weekdayIndex != targetState.weekdayIndex,
              sourceState.workout != nil else {
            return false
        }

        return true
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
    var selectedDayID: WeekdayWorkoutState.ID?
    var onSelect: (WeekdayWorkoutState) -> Void
    var onMove: (WorkoutDay, WeekdayWorkoutState) -> Void

    @State private var targetedDayID: WeekdayWorkoutState.ID?

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
                            calendarButton(for: state, date: date)
                        } else {
                            CalendarDayCell(
                                day: calendar.component(.day, from: date),
                                isCurrentMonth: calendar.isDate(date, equalTo: monthDate, toGranularity: .month),
                                isSelected: false,
                                isDropTargeted: false,
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

    @ViewBuilder
    private func calendarButton(for state: WeekdayWorkoutState, date: Date) -> some View {
        if let workout = state.workout {
            baseCalendarButton(for: state, date: date)
                .onDrag {
                    NSItemProvider(object: dragPayload(for: workout) as NSString)
                }
                .onDrop(
                    of: [UTType.text],
                    isTargeted: dropTargetBinding(for: state),
                    perform: { providers in handleDrop(providers, onto: state) }
                )
        } else {
            baseCalendarButton(for: state, date: date)
                .onDrop(
                    of: [UTType.text],
                    isTargeted: dropTargetBinding(for: state),
                    perform: { providers in handleDrop(providers, onto: state) }
                )
        }
    }

    private func baseCalendarButton(for state: WeekdayWorkoutState, date: Date) -> some View {
        Button {
            onSelect(state)
        } label: {
            CalendarDayCell(
                day: calendar.component(.day, from: date),
                isCurrentMonth: calendar.isDate(date, equalTo: monthDate, toGranularity: .month),
                isSelected: selectedDayID == state.id,
                isDropTargeted: targetedDayID == state.id,
                status: state.status
            )
        }
        .buttonStyle(.plain)
    }

    private func dragPayload(for workout: WorkoutDay) -> String {
        "\(workout.weekNumber)|\(workout.id.uuidString)"
    }

    private func dropTargetBinding(for state: WeekdayWorkoutState) -> Binding<Bool> {
        Binding(
            get: { targetedDayID == state.id },
            set: { isTargeted in
                targetedDayID = isTargeted ? state.id : nil
            }
        )
    }

    private func handleDrop(_ providers: [NSItemProvider], onto targetState: WeekdayWorkoutState) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.text.identifier) }) else {
            return false
        }

        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
            guard let payload = payloadString(from: item),
                  let workout = workout(from: payload, targetWeekNumber: targetState.weekNumber) else {
                return
            }

            DispatchQueue.main.async {
                onMove(workout, targetState)
                targetedDayID = nil
            }
        }

        return true
    }

    private func payloadString(from item: NSSecureCoding?) -> String? {
        if let string = item as? String {
            return string
        }

        if let string = item as? NSString {
            return String(string)
        }

        if let data = item as? Data {
            return String(data: data, encoding: .utf8)
        }

        return nil
    }

    private func workout(from payload: String, targetWeekNumber: Int) -> WorkoutDay? {
        let parts = payload.split(separator: "|")
        guard parts.count == 2,
              let weekNumber = Int(parts[0]),
              weekNumber == targetWeekNumber,
              let workoutID = UUID(uuidString: String(parts[1])) else {
            return nil
        }

        return states
            .compactMap(\.workout)
            .first { $0.id == workoutID && $0.weekNumber == targetWeekNumber }
    }
}

private struct CalendarDayCell: View {
    var day: Int
    var isCurrentMonth: Bool
    var isSelected: Bool
    var isDropTargeted: Bool
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
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(borderColor, lineWidth: isDropTargeted || isSelected ? 1.6 : 1)
        )
    }

    private var backgroundColor: Color {
        if isDropTargeted {
            return CoachTheme.accentBlue.opacity(0.26)
        }

        if isSelected {
            return statusColor.opacity(0.22)
        }

        return CoachTheme.surfaceStrong.opacity(status == nil ? 0.18 : 0.52)
    }

    private var borderColor: Color {
        if isDropTargeted {
            return CoachTheme.accentBlue.opacity(0.84)
        }

        if isSelected {
            return statusColor.opacity(0.7)
        }

        return CoachTheme.stroke
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
    var selectedDayID: WeekdayWorkoutState.ID?
    var onSelect: (WeekdayWorkoutState) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Training Block Schedule")
                .font(.headline.weight(.semibold))
                .foregroundStyle(CoachTheme.primaryText)

            VStack(spacing: 10) {
                ForEach(states) { state in
                    Button {
                        onSelect(state)
                    } label: {
                        ScheduleDayRow(state: state, isSelected: selectedDayID == state.id)
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
            return "Week \(state.weekNumber) • Recovery planned"
        }
        return "Week \(state.weekNumber) • \(workout.estimatedDurationMinutes) min • \(workout.muscleFocus.prefix(3).map(\.rawValue).joined(separator: " • "))"
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

private struct MoveDayButton: View {
    var state: WeekdayWorkoutState
    var isCurrentDay: Bool
    var canMove: Bool
    var onMove: () -> Void

    var body: some View {
        Button(action: onMove) {
            VStack(spacing: 6) {
                Text(weekdayShort)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(CoachTheme.secondaryText)
                Text(dayNumber)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(CoachTheme.primaryText)
                    .monospacedDigit()
                Text(actionTitle)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(isCurrentDay ? CoachTheme.accentMint : statusColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 76)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isCurrentDay ? CoachTheme.accentMint.opacity(0.55) : statusColor.opacity(canMove ? 0.42 : 0.16), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!canMove)
        .opacity(isCurrentDay || canMove ? 1 : 0.44)
    }

    private var weekdayShort: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: state.date)
    }

    private var dayNumber: String {
        "\(Calendar.current.component(.day, from: state.date))"
    }

    private var actionTitle: String {
        if isCurrentDay {
            return "Current"
        }
        return state.workout == nil ? "Move" : "Swap"
    }

    private var backgroundColor: Color {
        if isCurrentDay {
            return CoachTheme.accentMint.opacity(0.14)
        }
        return CoachTheme.surfaceStrong.opacity(canMove ? 0.72 : 0.36)
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
            return CoachTheme.secondaryText
        }
    }
}

private struct MoveWorkoutHereRow: View {
    var sourceState: WeekdayWorkoutState
    var onMove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.triangle.branch")
                .font(.headline.weight(.semibold))
                .foregroundStyle(CoachTheme.accentBlue)
                .frame(width: 42, height: 42)
                .background(CoachTheme.accentBlue.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(sourceState.workout?.title ?? "Workout")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(CoachTheme.primaryText)
                    .lineLimit(1)
                Text("From \(weekdayName)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CoachTheme.secondaryText)
            }

            Spacer()

            Button(action: onMove) {
                Text("Move")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 34)
                    .background(CoachTheme.accentBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(CoachTheme.surface.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(CoachTheme.stroke, lineWidth: 1)
        )
    }

    private var weekdayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: sourceState.date)
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
            if exercise.targetReps.upperBound <= 1, exercise.workDuration >= 60 {
                return "\(exercise.sets) set x \(Int(exercise.workDuration / 60)) min"
            }
            return "\(exercise.sets) sets x \(exercise.targetReps.label) reps"
        }
        return "\(Int(exercise.workDuration)) sec \(exercise.phase.rawValue.lowercased())"
    }
}
