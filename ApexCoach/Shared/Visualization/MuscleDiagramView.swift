import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum MuscleDiagramViewMode {
    case front
    case back

    var assetName: String {
        switch self {
        case .front:
            return "body_front"
        case .back:
            return "body_back"
        }
    }
}

struct MuscleDiagramView: View {
    var primaryMuscles: [MuscleGroup]
    var secondaryMuscles: [MuscleGroup]
    var viewMode: MuscleDiagramViewMode

    private var primary: Set<MuscleGroup> { Set(primaryMuscles) }
    private var secondary: Set<MuscleGroup> { Set(secondaryMuscles) }

    init(
        primaryMuscles: [MuscleGroup],
        secondaryMuscles: [MuscleGroup],
        viewMode: MuscleDiagramViewMode
    ) {
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.viewMode = viewMode
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.055), Color.black.opacity(0.18)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                if hasLocalBodyAsset {
                    Image(viewMode.assetName)
                        .resizable()
                        .scaledToFit()
                        .padding(height * 0.045)
                        .frame(width: width, height: height)
                        .opacity(0.92)
                } else {
                    fallbackBody(width: width, height: height)
                }

                MuscleOverlayRegions(
                    primaryMuscles: primary,
                    secondaryMuscles: secondary,
                    viewMode: viewMode
                )
                .padding(height * 0.045)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(CoachTheme.stroke, lineWidth: 1)
            )
        }
        .aspectRatio(0.72, contentMode: .fit)
    }

    private var hasLocalBodyAsset: Bool {
        #if canImport(UIKit)
        return UIImage(named: viewMode.assetName) != nil
        #elseif canImport(AppKit)
        return NSImage(named: viewMode.assetName) != nil
        #else
        return true
        #endif
    }

    private func fallbackBody(width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: height * 0.025) {
            head(width: width)
            torso(width: width, height: height)
            legs(width: width, height: height)
        }
        .padding(.vertical, height * 0.06)
    }

    private func head(width: CGFloat) -> some View {
        VStack(spacing: 2) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.36), Color.white.opacity(0.16)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: width * 0.18, height: width * 0.18)
                .overlay(Circle().stroke(Color.white.opacity(0.16), lineWidth: 1))
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.16))
                .frame(width: width * 0.08, height: width * 0.05)
        }
    }

    private func torso(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            if viewMode == .front {
                VStack(spacing: height * 0.012) {
                    HStack(spacing: width * 0.018) {
                        musclePlate(.chest, width: width * 0.16, height: height * 0.125, radius: width * 0.045)
                        musclePlate(.chest, width: width * 0.16, height: height * 0.125, radius: width * 0.045)
                    }

                    VStack(spacing: height * 0.006) {
                        ForEach(0..<4, id: \.self) { _ in
                            HStack(spacing: width * 0.012) {
                                musclePlate(.core, width: width * 0.09, height: height * 0.033, radius: width * 0.012)
                                musclePlate(.core, width: width * 0.09, height: height * 0.033, radius: width * 0.012)
                            }
                        }
                    }
                }
                .offset(y: height * 0.05)
            } else {
                VStack(spacing: height * 0.010) {
                    HStack(spacing: width * 0.018) {
                        musclePlate(.back, width: width * 0.15, height: height * 0.22, radius: width * 0.05)
                        musclePlate(.back, width: width * 0.15, height: height * 0.22, radius: width * 0.05)
                    }
                    RoundedRectangle(cornerRadius: width * 0.015)
                        .fill(Color.white.opacity(0.22))
                        .frame(width: width * 0.035, height: height * 0.19)
                        .offset(y: -height * 0.20)
                }
                .offset(y: height * 0.05)
            }

            HStack(spacing: width * 0.33) {
                limb(.shoulders, width: width * 0.13, height: height * 0.105)
                    .rotationEffect(.degrees(16))
                limb(.shoulders, width: width * 0.13, height: height * 0.105)
                    .rotationEffect(.degrees(-16))
            }
            .offset(y: -height * 0.065)

            HStack(spacing: width * 0.45) {
                arm(width: width, height: height, isLeading: true)
                arm(width: width, height: height, isLeading: false)
            }
            .offset(y: height * 0.07)
        }
        .frame(width: width, height: height * 0.40)
    }

    private func arm(width: CGFloat, height: CGFloat, isLeading: Bool) -> some View {
        VStack(spacing: height * 0.012) {
            limb(viewMode == .front ? .biceps : .triceps, width: width * 0.075, height: height * 0.125)
            limb(.triceps, width: width * 0.062, height: height * 0.12)
        }
        .rotationEffect(.degrees(isLeading ? 8 : -8))
    }

    private func legs(width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: height * 0.012) {
            if viewMode == .back {
                RoundedRectangle(cornerRadius: width * 0.05, style: .continuous)
                    .fill(color(for: .glutes))
                    .frame(width: width * 0.28, height: height * 0.075)
            }

            HStack(spacing: width * 0.06) {
                leg(width: width, height: height)
                leg(width: width, height: height)
            }
        }
        .frame(width: width, height: height * 0.34)
    }

    private func leg(width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: height * 0.015) {
            limb(viewMode == .front ? .quads : .hamstrings, width: width * 0.12, height: height * 0.17)
            limb(.calves, width: width * 0.095, height: height * 0.13)
        }
    }

    private func limb(_ muscle: MuscleGroup, width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: min(width, height) * 0.45, style: .continuous)
            .fill(color(for: muscle))
            .frame(width: width, height: height)
            .overlay(
                LinearGradient(
                    colors: [Color.white.opacity(0.28), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: min(width, height) * 0.45, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: min(width, height) * 0.45, style: .continuous)
                    .stroke(Color.white.opacity(isActivated(muscle) ? 0.24 : 0.08), lineWidth: 1)
            )
            .shadow(color: color(for: muscle).opacity(isActivated(muscle) ? 0.36 : 0.04), radius: isActivated(muscle) ? 10 : 2)
    }

    private func musclePlate(_ muscle: MuscleGroup, width: CGFloat, height: CGFloat, radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(color(for: muscle))
            .frame(width: width, height: height)
            .overlay(
                LinearGradient(
                    colors: [Color.white.opacity(0.30), Color.clear, Color.black.opacity(0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.white.opacity(isActivated(muscle) ? 0.22 : 0.08), lineWidth: 1)
            )
            .shadow(color: color(for: muscle).opacity(isActivated(muscle) ? 0.28 : 0.03), radius: isActivated(muscle) ? 9 : 2)
    }

    private func color(for muscle: MuscleGroup) -> Color {
        if primary.contains(muscle) || primary.contains(.fullBody) {
            return CoachTheme.muscle
        }
        if secondary.contains(muscle) || secondary.contains(.fullBody) {
            return CoachTheme.muscle.opacity(0.58)
        }
        if muscle == .glutes && (primary.contains(.glutes) || secondary.contains(.glutes)) {
            return primary.contains(.glutes) ? CoachTheme.muscle : CoachTheme.muscle.opacity(0.58)
        }
        return Color.white.opacity(0.18)
    }

    private func isActivated(_ muscle: MuscleGroup) -> Bool {
        primary.contains(muscle) || secondary.contains(muscle) || primary.contains(.fullBody) || secondary.contains(.fullBody)
    }
}

private struct MuscleOverlayRegions: View {
    var primaryMuscles: Set<MuscleGroup>
    var secondaryMuscles: Set<MuscleGroup>
    var viewMode: MuscleDiagramViewMode

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                if viewMode == .front {
                    frontRegions(width: width, height: height)
                } else {
                    backRegions(width: width, height: height)
                }
            }
            .frame(width: width, height: height)
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func frontRegions(width: CGFloat, height: CGFloat) -> some View {
        pairedRegion(.chest, x: 0.5, y: 0.255, width: 0.205, height: 0.115, spacing: 0.106, radius: 0.035, canvas: CGSize(width: width, height: height))
        pairedRegion(.shoulders, x: 0.5, y: 0.232, width: 0.135, height: 0.070, spacing: 0.328, radius: 0.032, canvas: CGSize(width: width, height: height), rotation: 12)
        pairedRegion(.biceps, x: 0.5, y: 0.380, width: 0.098, height: 0.220, spacing: 0.500, radius: 0.040, canvas: CGSize(width: width, height: height), rotation: 8)
        pairedRegion(.triceps, x: 0.5, y: 0.380, width: 0.082, height: 0.220, spacing: 0.515, radius: 0.035, canvas: CGSize(width: width, height: height), rotation: 8)
        pairedRegion(.core, x: 0.5, y: 0.410, width: 0.118, height: 0.260, spacing: 0.070, radius: 0.018, canvas: CGSize(width: width, height: height))
        pairedRegion(.quads, x: 0.5, y: 0.684, width: 0.126, height: 0.225, spacing: 0.184, radius: 0.045, canvas: CGSize(width: width, height: height))
        pairedRegion(.calves, x: 0.5, y: 0.858, width: 0.092, height: 0.160, spacing: 0.184, radius: 0.040, canvas: CGSize(width: width, height: height))
    }

    @ViewBuilder
    private func backRegions(width: CGFloat, height: CGFloat) -> some View {
        pairedRegion(.back, x: 0.5, y: 0.340, width: 0.170, height: 0.270, spacing: 0.154, radius: 0.052, canvas: CGSize(width: width, height: height))
        pairedRegion(.shoulders, x: 0.5, y: 0.232, width: 0.135, height: 0.070, spacing: 0.328, radius: 0.032, canvas: CGSize(width: width, height: height), rotation: 12)
        pairedRegion(.triceps, x: 0.5, y: 0.395, width: 0.095, height: 0.235, spacing: 0.510, radius: 0.038, canvas: CGSize(width: width, height: height), rotation: 8)
        pairedRegion(.biceps, x: 0.5, y: 0.395, width: 0.078, height: 0.215, spacing: 0.520, radius: 0.034, canvas: CGSize(width: width, height: height), rotation: 8)
        pairedRegion(.glutes, x: 0.5, y: 0.565, width: 0.145, height: 0.112, spacing: 0.146, radius: 0.040, canvas: CGSize(width: width, height: height))
        pairedRegion(.hamstrings, x: 0.5, y: 0.708, width: 0.128, height: 0.225, spacing: 0.184, radius: 0.045, canvas: CGSize(width: width, height: height))
        pairedRegion(.calves, x: 0.5, y: 0.858, width: 0.092, height: 0.160, spacing: 0.184, radius: 0.040, canvas: CGSize(width: width, height: height))
    }

    @ViewBuilder
    private func pairedRegion(
        _ muscle: MuscleGroup,
        x: CGFloat,
        y: CGFloat,
        width regionWidth: CGFloat,
        height regionHeight: CGFloat,
        spacing: CGFloat,
        radius: CGFloat,
        canvas: CGSize,
        rotation: Double = 0
    ) -> some View {
        if let color = highlightColor(for: muscle) {
            muscleShape(color: color, radius: canvas.width * radius)
                .frame(width: canvas.width * regionWidth, height: canvas.height * regionHeight)
                .rotationEffect(.degrees(-rotation))
                .position(x: canvas.width * (x - spacing / 2), y: canvas.height * y)

            muscleShape(color: color, radius: canvas.width * radius)
                .frame(width: canvas.width * regionWidth, height: canvas.height * regionHeight)
                .rotationEffect(.degrees(rotation))
                .position(x: canvas.width * (x + spacing / 2), y: canvas.height * y)
        }
    }

    private func muscleShape(color: Color, radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [color.opacity(0.95), color.opacity(0.68)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.45), radius: 12)
            .blendMode(.plusLighter)
    }

    private func highlightColor(for muscle: MuscleGroup) -> Color? {
        if primaryMuscles.contains(.fullBody) || primaryMuscles.contains(muscle) {
            return Color(red: 1.0, green: 0.23, blue: 0.12)
        }
        if secondaryMuscles.contains(.fullBody) || secondaryMuscles.contains(muscle) {
            return Color(red: 1.0, green: 0.55, blue: 0.22).opacity(0.72)
        }
        return nil
    }
}

struct WorkoutThumbnail: View {
    var primaryMuscles: [MuscleGroup]
    var secondaryMuscles: [MuscleGroup]
    var phase: ExercisePhase

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.12), Color.black.opacity(0.30)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if phase == .warmUp {
                Image(systemName: "figure.cooldown")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(CoachTheme.accentGold)
            } else if phase == .stretching {
                Image(systemName: "figure.flexibility")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(CoachTheme.accentMint)
            } else {
                MiniBodySilhouette(primaryMuscles: primaryMuscles, secondaryMuscles: secondaryMuscles)
                    .padding(5)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(CoachTheme.stroke, lineWidth: 1)
        )
    }
}

struct HeroMuscleFigure: View {
    var primaryMuscles: [MuscleGroup]
    var secondaryMuscles: [MuscleGroup]
    var pose: HeroPose = .standing

    var body: some View {
        ZStack {
            if pose == .bench {
                BenchPoseFigure(primaryMuscles: primaryMuscles, secondaryMuscles: secondaryMuscles)
            } else {
                MiniBodySilhouette(primaryMuscles: primaryMuscles, secondaryMuscles: secondaryMuscles)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
            }
        }
        .drawingGroup()
    }
}

enum HeroPose {
    case standing
    case bench
}

private struct MiniBodySilhouette: View {
    var primaryMuscles: [MuscleGroup]
    var secondaryMuscles: [MuscleGroup]

    private var primary: Set<MuscleGroup> { Set(primaryMuscles) }
    private var secondary: Set<MuscleGroup> { Set(secondaryMuscles) }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            ZStack {
                Ellipse()
                    .fill(Color.black.opacity(0.38))
                    .frame(width: width * 0.66, height: height * 0.10)
                    .offset(y: height * 0.45)

                VStack(spacing: height * 0.026) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.38), Color.white.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: width * 0.18, height: width * 0.18)
                        .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
                    torso(width: width, height: height)
                    HStack(spacing: width * 0.07) {
                        leg(width: width, height: height, muscle: .quads)
                        leg(width: width, height: height, muscle: .quads)
                    }
                }
            }
        }
    }

    private func torso(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            VStack(spacing: height * 0.010) {
                HStack(spacing: width * 0.016) {
                    capsule(.chest, width: width * 0.17, height: height * 0.12, corner: width * 0.04)
                    capsule(.chest, width: width * 0.17, height: height * 0.12, corner: width * 0.04)
                }
                VStack(spacing: height * 0.006) {
                    ForEach(0..<3, id: \.self) { _ in
                        HStack(spacing: width * 0.012) {
                            capsule(.core, width: width * 0.085, height: height * 0.034, corner: width * 0.012)
                            capsule(.core, width: width * 0.085, height: height * 0.034, corner: width * 0.012)
                        }
                    }
                }
            }
            .offset(y: height * 0.04)

            HStack(spacing: width * 0.42) {
                arm(width: width, height: height)
                arm(width: width, height: height)
            }
            .offset(y: height * 0.04)
        }
        .frame(width: width, height: height * 0.39)
    }

    private func arm(width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: height * 0.012) {
            capsule(.shoulders, width: width * 0.085, height: height * 0.12)
            capsule(.triceps, width: width * 0.067, height: height * 0.14)
        }
    }

    private func leg(width: CGFloat, height: CGFloat, muscle: MuscleGroup) -> some View {
        VStack(spacing: height * 0.014) {
            capsule(muscle, width: width * 0.12, height: height * 0.19)
            capsule(.calves, width: width * 0.09, height: height * 0.14)
        }
    }

    private func capsule(_ muscle: MuscleGroup, width: CGFloat, height: CGFloat, corner: CGFloat? = nil) -> some View {
        RoundedRectangle(cornerRadius: corner ?? min(width, height) * 0.45, style: .continuous)
            .fill(color(for: muscle))
            .frame(width: width, height: height)
            .overlay(
                LinearGradient(
                    colors: [Color.white.opacity(0.30), Color.clear, Color.black.opacity(0.12)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: corner ?? min(width, height) * 0.45, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner ?? min(width, height) * 0.45, style: .continuous)
                    .stroke(Color.white.opacity(isActivated(muscle) ? 0.22 : 0.06), lineWidth: 1)
            )
            .shadow(color: color(for: muscle).opacity(isActivated(muscle) ? 0.28 : 0.03), radius: isActivated(muscle) ? 8 : 2)
    }

    private func color(for muscle: MuscleGroup) -> Color {
        if primary.contains(muscle) || primary.contains(.fullBody) {
            return CoachTheme.muscle
        }
        if secondary.contains(muscle) || secondary.contains(.fullBody) {
            return CoachTheme.muscle.opacity(0.58)
        }
        return Color.white.opacity(0.26)
    }

    private func isActivated(_ muscle: MuscleGroup) -> Bool {
        primary.contains(muscle) || secondary.contains(muscle) || primary.contains(.fullBody) || secondary.contains(.fullBody)
    }
}

private struct BenchPoseFigure: View {
    var primaryMuscles: [MuscleGroup]
    var secondaryMuscles: [MuscleGroup]

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            ZStack {
                Ellipse()
                    .fill(Color.black.opacity(0.34))
                    .frame(width: width * 0.82, height: height * 0.11)
                    .offset(y: height * 0.30)

                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.20))
                    .frame(width: width * 0.68, height: 9)
                    .offset(y: height * 0.20)

                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.30))
                    .frame(width: width * 0.86, height: 5)
                    .offset(y: -height * 0.20)

                Circle()
                    .stroke(Color.white.opacity(0.34), lineWidth: 4)
                    .frame(width: width * 0.13, height: width * 0.13)
                    .offset(x: -width * 0.45, y: -height * 0.20)
                Circle()
                    .stroke(Color.white.opacity(0.34), lineWidth: 4)
                    .frame(width: width * 0.13, height: width * 0.13)
                    .offset(x: width * 0.45, y: -height * 0.20)

                HStack(spacing: width * 0.02) {
                    benchMuscle(.chest, width: width * 0.20, height: height * 0.15)
                    benchMuscle(.chest, width: width * 0.20, height: height * 0.15)
                }
                .rotationEffect(.degrees(-8))
                .offset(y: height * 0.02)

                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.18))
                    .frame(width: width * 0.26, height: height * 0.12)
                    .rotationEffect(.degrees(-8))
                    .offset(x: width * 0.20, y: height * 0.06)

                HStack(spacing: width * 0.42) {
                    benchMuscle(.triceps, width: width * 0.10, height: height * 0.30)
                        .rotationEffect(.degrees(-38))
                    benchMuscle(.triceps, width: width * 0.10, height: height * 0.30)
                        .rotationEffect(.degrees(38))
                }
                .offset(y: -height * 0.08)

                Circle()
                    .fill(Color.white.opacity(0.24))
                    .frame(width: width * 0.14, height: width * 0.14)
                    .offset(x: -width * 0.27, y: height * 0.03)
            }
        }
    }

    private func benchMuscle(_ muscle: MuscleGroup, width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: min(width, height) * 0.45, style: .continuous)
            .fill(muscleColor(muscle))
            .frame(width: width, height: height)
            .overlay(
                LinearGradient(
                    colors: [Color.white.opacity(0.28), Color.clear, Color.black.opacity(0.16)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: min(width, height) * 0.45, style: .continuous))
            )
            .shadow(color: muscleColor(muscle).opacity(primaryMuscles.contains(muscle) ? 0.35 : 0.06), radius: primaryMuscles.contains(muscle) ? 10 : 2)
    }

    private func muscleColor(_ muscle: MuscleGroup) -> Color {
        if primaryMuscles.contains(muscle) {
            return CoachTheme.muscle
        }
        if secondaryMuscles.contains(muscle) {
            return CoachTheme.muscle.opacity(0.58)
        }
        return Color.white.opacity(0.24)
    }
}

struct MuscleMiniGlyph: View {
    var primaryMuscles: [MuscleGroup]

    var body: some View {
        ZStack {
            Circle()
                .fill(CoachTheme.surfaceStrong)
            Image(systemName: iconName)
                .font(.headline)
                .foregroundStyle(CoachTheme.accentMint)
        }
        .overlay(Circle().stroke(CoachTheme.stroke, lineWidth: 1))
    }

    private var iconName: String {
        let muscles = Set(primaryMuscles)
        if muscles.contains(.quads) || muscles.contains(.hamstrings) || muscles.contains(.glutes) {
            return "figure.strengthtraining.traditional"
        }
        if muscles.contains(.core) {
            return "figure.core.training"
        }
        if muscles.contains(.back) {
            return "figure.pullup"
        }
        return "dumbbell.fill"
    }
}
