import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @State private var hasDismissedWelcome = false

    var body: some View {
        Group {
            if appModel.isBootstrapping {
                LaunchLoadingView()
            } else if !hasDismissedWelcome {
                WelcomeNoteView {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
                        hasDismissedWelcome = true
                    }
                }
            } else if appModel.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingFlowView()
            }
        }
        .coachBackground()
        .alert("Apex Coach", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                appModel.errorMessage = nil
            }
        } message: {
            Text(appModel.errorMessage ?? "")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { appModel.errorMessage != nil },
            set: { if !$0 { appModel.errorMessage = nil } }
        )
    }
}

private struct WelcomeNoteView: View {
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 34)

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .fill(CoachTheme.accentBlue.opacity(0.16))
                        .frame(width: 148, height: 148)
                    ProgressRing(progress: 1, lineWidth: 10, gradient: CoachTheme.accentGradient)
                        .frame(width: 122, height: 122)
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 46, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 10) {
                    Text("Welcome to Apex Coach")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(CoachTheme.primaryText)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.78)

                    Text("Your local training plan is ready to move with you.")
                        .font(.headline.weight(.medium))
                        .foregroundStyle(CoachTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }
            .frame(maxWidth: .infinity)

            Spacer()

            PrimaryCoachButton(title: "Continue", systemImage: "arrow.right") {
                onContinue()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RadialGradient(
                colors: [CoachTheme.accentBlue.opacity(0.18), CoachTheme.background, Color.black],
                center: .top,
                startRadius: 20,
                endRadius: 700
            )
            .ignoresSafeArea()
        )
    }
}

private struct LaunchLoadingView: View {
    var body: some View {
        VStack(spacing: 18) {
            ProgressRing(progress: 0.72, lineWidth: 10)
                .frame(width: 82, height: 82)
            Text("Apex Coach")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(CoachTheme.primaryText)
            Text("Loading your local training system")
                .font(.subheadline)
                .foregroundStyle(CoachTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            WorkoutPlanView()
                .tabItem {
                    Label("Workouts", systemImage: "dumbbell")
                }

            ProgressViewScreen()
                .tabItem {
                    Label("Progress", systemImage: "chart.xyaxis.line")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
        .tint(CoachTheme.accentMint)
    }
}
