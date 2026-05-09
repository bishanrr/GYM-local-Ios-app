import SwiftUI

enum MuscleDiagramSide {
    case front
    case back
}

struct MuscleDiagramView: View {
    var primaryMuscles: [MuscleGroup]
    var secondaryMuscles: [MuscleGroup]
    var side: MuscleDiagramSide

    private var primary: Set<MuscleGroup> { Set(primaryMuscles) }
    private var secondary: Set<MuscleGroup> { Set(secondaryMuscles) }

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

                VStack(spacing: height * 0.025) {
                    head(width: width)
                    torso(width: width, height: height)
                    legs(width: width, height: height)
                }
                .padding(.vertical, height * 0.06)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(CoachTheme.stroke, lineWidth: 1)
            )
        }
        .aspectRatio(0.72, contentMode: .fit)
    }

    private func head(width: CGFloat) -> some View {
        Circle()
            .fill(Color.white.opacity(0.20))
            .frame(width: width * 0.18, height: width * 0.18)
            .overlay(Circle().stroke(Color.white.opacity(0.16), lineWidth: 1))
    }

    private func torso(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: width * 0.10, style: .continuous)
                .fill(color(for: side == .front ? .chest : .back))
                .frame(width: width * 0.32, height: height * 0.27)
                .offset(y: height * 0.015)

            RoundedRectangle(cornerRadius: width * 0.05, style: .continuous)
                .fill(color(for: .core))
                .frame(width: width * 0.22, height: height * 0.20)
                .offset(y: height * 0.105)

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
            limb(side == .front ? .biceps : .triceps, width: width * 0.075, height: height * 0.125)
            limb(.triceps, width: width * 0.062, height: height * 0.12)
        }
        .rotationEffect(.degrees(isLeading ? 8 : -8))
    }

    private func legs(width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: height * 0.012) {
            if side == .back {
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
            limb(side == .front ? .quads : .hamstrings, width: width * 0.12, height: height * 0.17)
            limb(.calves, width: width * 0.095, height: height * 0.13)
        }
    }

    private func limb(_ muscle: MuscleGroup, width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: min(width, height) * 0.45, style: .continuous)
            .fill(color(for: muscle))
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: min(width, height) * 0.45, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
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
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CoachTheme.accentGold)
            } else if phase == .stretching {
                Image(systemName: "figure.flexibility")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CoachTheme.accentMint)
            } else {
                MiniBodySilhouette(primaryMuscles: primaryMuscles, secondaryMuscles: secondaryMuscles)
                    .padding(7)
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
                VStack(spacing: height * 0.026) {
                    Circle()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: width * 0.20, height: width * 0.20)
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
            RoundedRectangle(cornerRadius: width * 0.08, style: .continuous)
                .fill(color(for: .chest))
                .frame(width: width * 0.36, height: height * 0.26)
            RoundedRectangle(cornerRadius: width * 0.05, style: .continuous)
                .fill(color(for: .core))
                .frame(width: width * 0.24, height: height * 0.20)
                .offset(y: height * 0.09)
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
            capsule(.shoulders, width: width * 0.08, height: height * 0.12)
            capsule(.triceps, width: width * 0.064, height: height * 0.13)
        }
    }

    private func leg(width: CGFloat, height: CGFloat, muscle: MuscleGroup) -> some View {
        VStack(spacing: height * 0.014) {
            capsule(muscle, width: width * 0.12, height: height * 0.18)
            capsule(.calves, width: width * 0.09, height: height * 0.13)
        }
    }

    private func capsule(_ muscle: MuscleGroup, width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: min(width, height) * 0.45, style: .continuous)
            .fill(color(for: muscle))
            .frame(width: width, height: height)
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
}

private struct BenchPoseFigure: View {
    var primaryMuscles: [MuscleGroup]
    var secondaryMuscles: [MuscleGroup]

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            ZStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.16))
                    .frame(width: width * 0.62, height: 7)
                    .offset(y: height * 0.18)

                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.22))
                    .frame(width: width * 0.80, height: 4)
                    .offset(y: -height * 0.20)

                Circle()
                    .stroke(Color.white.opacity(0.28), lineWidth: 3)
                    .frame(width: width * 0.11, height: width * 0.11)
                    .offset(x: -width * 0.45, y: -height * 0.20)
                Circle()
                    .stroke(Color.white.opacity(0.28), lineWidth: 3)
                    .frame(width: width * 0.11, height: width * 0.11)
                    .offset(x: width * 0.45, y: -height * 0.20)

                RoundedRectangle(cornerRadius: height * 0.05, style: .continuous)
                    .fill(CoachTheme.muscle.opacity(primaryMuscles.contains(.chest) ? 1 : 0.42))
                    .frame(width: width * 0.40, height: height * 0.16)
                    .rotationEffect(.degrees(-8))
                    .offset(y: height * 0.02)

                HStack(spacing: width * 0.42) {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(CoachTheme.muscle.opacity(primaryMuscles.contains(.triceps) ? 1 : 0.58))
                        .frame(width: width * 0.10, height: height * 0.30)
                        .rotationEffect(.degrees(-38))
                    RoundedRectangle(cornerRadius: 9)
                        .fill(CoachTheme.muscle.opacity(primaryMuscles.contains(.triceps) ? 1 : 0.58))
                        .frame(width: width * 0.10, height: height * 0.30)
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
