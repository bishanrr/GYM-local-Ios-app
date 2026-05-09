import SwiftUI

struct PremiumCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content.premiumCardStyle()
    }
}

struct PrimaryCoachButton: View {
    var title: String
    var systemImage: String
    var isLoading: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: systemImage)
                        .font(.headline)
                }
                Text(title)
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(CoachTheme.accentGradient)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: CoachTheme.accentBlue.opacity(0.28), radius: 22, y: 12)
        }
        .disabled(isLoading)
        .buttonStyle(.plain)
    }
}

struct GlassIconButton: View {
    var systemImage: String
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(CoachTheme.primaryText)
                .frame(width: 44, height: 44)
                .background(CoachTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(CoachTheme.stroke, lineWidth: 1)
                )
        }
        .accessibilityLabel(title)
        .buttonStyle(.plain)
    }
}

struct MetricPill: View {
    var title: String
    var value: String
    var systemImage: String
    var tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .font(.subheadline.weight(.semibold))
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.16))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CoachTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(CoachTheme.secondaryText)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .frame(minHeight: 54)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(CoachTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(CoachTheme.stroke, lineWidth: 1)
        )
    }
}

struct ProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = 12
    var gradient: LinearGradient = CoachTheme.accentGradient

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.10), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(
                    gradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.85), value: progress)
        }
    }
}

struct SectionHeader: View {
    var title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(CoachTheme.primaryText)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(CoachTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SelectionChip: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : CoachTheme.secondaryText)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isSelected ? CoachTheme.accentPurple.opacity(0.88) : CoachTheme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isSelected ? CoachTheme.accentBlue.opacity(0.55) : CoachTheme.stroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct ExerciseSummaryRow: View {
    var exercise: Exercise
    var showsAccessory: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            MuscleMiniGlyph(primaryMuscles: exercise.primaryMuscles)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CoachTheme.primaryText)
                    .lineLimit(1)
                Text("\(exercise.sets)x \(exercise.targetReps.label) reps • \(Int(exercise.restDuration))s rest")
                    .font(.caption)
                    .foregroundStyle(CoachTheme.secondaryText)
                    .lineLimit(1)
            }
            Spacer()
            if showsAccessory {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(CoachTheme.tertiaryText)
            }
        }
        .frame(minHeight: 56)
    }
}

struct EmptyStateView: View {
    var title: String
    var subtitle: String
    var systemImage: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(CoachTheme.accentMint)
            Text(title)
                .font(.headline)
                .foregroundStyle(CoachTheme.primaryText)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(CoachTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .premiumCardStyle()
    }
}
