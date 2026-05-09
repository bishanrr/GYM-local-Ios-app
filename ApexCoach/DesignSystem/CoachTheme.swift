import SwiftUI

enum CoachTheme {
    static let background = Color(red: 0.015, green: 0.016, blue: 0.022)
    static let surface = Color.white.opacity(0.075)
    static let surfaceStrong = Color.white.opacity(0.12)
    static let stroke = Color.white.opacity(0.12)
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.68)
    static let tertiaryText = Color.white.opacity(0.44)
    static let accentPurple = Color(red: 0.52, green: 0.36, blue: 1.0)
    static let accentBlue = Color(red: 0.18, green: 0.64, blue: 1.0)
    static let accentMint = Color(red: 0.18, green: 0.92, blue: 0.70)
    static let accentCoral = Color(red: 1.0, green: 0.38, blue: 0.34)
    static let accentGold = Color(red: 1.0, green: 0.74, blue: 0.28)

    static let accentGradient = LinearGradient(
        colors: [accentPurple, accentBlue, accentMint],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let warmGradient = LinearGradient(
        colors: [accentCoral, accentGold],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension View {
    func coachBackground() -> some View {
        background(CoachTheme.background.ignoresSafeArea())
    }

    func premiumCardStyle() -> some View {
        padding(16)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(CoachTheme.stroke, lineWidth: 1)
                    )
            )
    }

    @ViewBuilder
    func coachInlineNavigationTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder
    func coachFullScreenCover<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        #if os(iOS)
        fullScreenCover(item: item, content: content)
        #else
        sheet(item: item, content: content)
        #endif
    }
}

extension TimeInterval {
    var clockString: String {
        let seconds = max(0, Int(self.rounded()))
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%02d:%02d", minutes, remainder)
    }
}

extension Double {
    var compactNumber: String {
        if self >= 1000 {
            return String(format: "%.1fk", self / 1000)
        }
        return String(format: "%.0f", self)
    }
}
