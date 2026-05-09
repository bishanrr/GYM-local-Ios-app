import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appModel: AppViewModel

    var body: some View {
        Group {
            if appModel.isBootstrapping {
                LaunchLoadingView()
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
                    Label("Plan", systemImage: "calendar")
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
