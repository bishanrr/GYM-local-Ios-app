import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @State private var isRefreshing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    profileSummary
                    aiControls
                    settings
                    localPrivacy
                }
                .padding(20)
            }
            .navigationTitle("Profile")
            .coachInlineNavigationTitle()
            .background(CoachTheme.background)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(appModel.snapshot.userProfile?.name ?? "Athlete")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(CoachTheme.primaryText)
            Text("Local-first coaching preferences and generation controls.")
                .font(.subheadline)
                .foregroundStyle(CoachTheme.secondaryText)
        }
    }

    private var profileSummary: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Training Profile", subtitle: "Used by the local generator and overload rules.")
                if let profile = appModel.snapshot.userProfile {
                    ProfileLine(title: "Goal", value: profile.goal.rawValue)
                    ProfileLine(title: "Experience", value: profile.experienceLevel.rawValue)
                    ProfileLine(title: "Days", value: "\(profile.workoutDaysPerWeek) per week")
                    ProfileLine(title: "Duration", value: profile.durationPreference.label)
                    ProfileLine(title: "Split", value: profile.preferredSplit.rawValue)
                    ProfileLine(title: "Equipment", value: profile.equipment.map(\.rawValue).joined(separator: ", "))
                }
            }
        }
    }

    private var aiControls: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Plan Generation", subtitle: "These are the only actions that invoke the generator.")
                PrimaryCoachButton(title: "Refresh Workouts", systemImage: "arrow.triangle.2.circlepath", isLoading: isRefreshing) {
                    refreshPlan()
                }

                Button {
                    refreshPlan()
                } label: {
                    Label("Generate New Program", systemImage: "sparkles")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .buttonStyle(OutlineProfileButtonStyle(tint: CoachTheme.accentMint))

                Button {
                    appModel.resetOnboarding()
                } label: {
                    Label("Change Workout Plan", systemImage: "slider.horizontal.3")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .buttonStyle(OutlineProfileButtonStyle(tint: CoachTheme.accentBlue))
            }
        }
    }

    private var settings: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Settings", subtitle: "Saved locally with your workout data.")
                Toggle("Dark Mode", isOn: Binding(
                    get: { appModel.snapshot.settings.darkMode },
                    set: { appModel.setDarkMode($0) }
                ))
                .tint(CoachTheme.accentMint)

                Toggle("Notifications", isOn: Binding(
                    get: { appModel.snapshot.settings.notificationsEnabled },
                    set: { appModel.setNotifications($0) }
                ))
                .tint(CoachTheme.accentMint)

                Picker("Units", selection: Binding(
                    get: { appModel.snapshot.settings.units },
                    set: { appModel.setUnits($0) }
                )) {
                    ForEach(UnitsPreference.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
            }
            .foregroundStyle(CoachTheme.primaryText)
        }
    }

    private var localPrivacy: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Offline by Default", systemImage: "lock.shield.fill")
                    .font(.headline)
                    .foregroundStyle(CoachTheme.accentMint)
                Text("Profiles, plans, workout history, performance, and PRs are persisted in local JSON. The app only regenerates workouts when you explicitly tap a generation control.")
                    .font(.subheadline)
                    .foregroundStyle(CoachTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func refreshPlan() {
        isRefreshing = true
        Task {
            await appModel.refreshWorkouts()
            isRefreshing = false
        }
    }
}

private struct ProfileLine: View {
    var title: String
    var value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(CoachTheme.secondaryText)
            Spacer(minLength: 16)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CoachTheme.primaryText)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct OutlineProfileButtonStyle: ButtonStyle {
    var tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(tint)
            .background(CoachTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(tint.opacity(configuration.isPressed ? 0.8 : 0.34), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
