import SwiftUI

@main
struct ApexCoachApp: App {
    @StateObject private var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appViewModel)
                .preferredColorScheme(appViewModel.snapshot.settings.darkMode ? .dark : nil)
        }
    }
}
