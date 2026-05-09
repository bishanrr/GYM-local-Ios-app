import SwiftUI

enum CoachTheme {
    static let background = Color(red: 0.015, green: 0.017, blue: 0.020)
    static let surface = Color(red: 0.075, green: 0.078, blue: 0.088)
    static let surfaceStrong = Color(red: 0.112, green: 0.116, blue: 0.132)
    static let stroke = Color.white.opacity(0.075)
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.68)
    static let tertiaryText = Color.white.opacity(0.44)
    static let accentPurple = Color(red: 0.36, green: 0.34, blue: 1.0)
    static let accentBlue = Color(red: 0.32, green: 0.40, blue: 1.0)
    static let accentMint = Color(red: 0.28, green: 0.82, blue: 0.74)
    static let accentCoral = Color(red: 1.0, green: 0.38, blue: 0.34)
    static let accentGold = Color(red: 1.0, green: 0.74, blue: 0.28)
    static let muscle = Color(red: 1.0, green: 0.42, blue: 0.22)

    static let accentGradient = LinearGradient(
        colors: [accentBlue, accentPurple],
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
        background(
            RadialGradient(
                colors: [Color.white.opacity(0.045), CoachTheme.background, Color.black],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 640
            )
            .ignoresSafeArea()
        )
    }

    func premiumCardStyle() -> some View {
        padding(16)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(CoachTheme.surface.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(CoachTheme.stroke, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.24), radius: 20, y: 12)
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
