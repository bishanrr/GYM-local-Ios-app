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
            .shadow(color: CoachTheme.accentBlue.opacity(0.30), radius: 18, y: 10)
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
                .background(CoachTheme.surfaceStrong)
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
        .background(CoachTheme.surfaceStrong.opacity(0.72))
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
                        .fill(isSelected ? CoachTheme.accentGradient : LinearGradient(colors: [CoachTheme.surfaceStrong, CoachTheme.surface], startPoint: .topLeading, endPoint: .bottomTrailing))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isSelected ? Color.white.opacity(0.22) : CoachTheme.stroke, lineWidth: 1)
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
            WorkoutThumbnail(primaryMuscles: exercise.primaryMuscles, secondaryMuscles: exercise.secondaryMuscles, phase: exercise.phase)
                .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CoachTheme.primaryText)
                    .lineLimit(1)
                Text(exercise.phase == .main ? "\(exercise.sets) sets x \(exercise.targetReps.label) reps" : "\(Int(exercise.workDuration)) sec • \(exercise.phase.rawValue)")
                    .font(.caption)
                    .foregroundStyle(CoachTheme.secondaryText)
                    .lineLimit(1)
            }
            Spacer()
            if showsAccessory {
                Image(systemName: "ellipsis")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(CoachTheme.tertiaryText)
            }
        }
        .frame(minHeight: 66)
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

struct CoachSegmentedControl: View {
    var items: [String]
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items, id: \.self) { item in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                        selection = item
                    }
                } label: {
                    Text(item)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(selection == item ? CoachTheme.primaryText : CoachTheme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(selection == item ? Color.white.opacity(0.12) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(CoachTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(CoachTheme.stroke, lineWidth: 1)
        )
    }
}

struct WeekProgressStrip: View {
    var completedCount: Int
    var totalCount: Int
    private let labels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(labels.indices, id: \.self) { index in
                VStack(spacing: 8) {
                    Text(labels[index])
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(CoachTheme.secondaryText)
                    Image(systemName: index < completedCount ? "checkmark" : "circle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(index < completedCount ? .white : Color.white.opacity(0.20))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(index < totalCount ? (index < completedCount ? CoachTheme.accentBlue.opacity(0.9) : CoachTheme.surfaceStrong) : CoachTheme.surface.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }
}

struct MiniVolumeChart: View {
    var values: [Double]
    var highlightedIndex: Int? = nil

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(values.indices, id: \.self) { index in
                Capsule()
                    .fill(index == highlightedIndex ? CoachTheme.accentGradient : LinearGradient(colors: [CoachTheme.accentPurple.opacity(0.75), CoachTheme.accentBlue.opacity(0.75)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 7, height: max(10, normalized(values[index]) * 70))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 78, alignment: .bottom)
    }

    private func normalized(_ value: Double) -> CGFloat {
        let maxValue = max(values.max() ?? 1, 1)
        return CGFloat(value / maxValue)
    }
}

struct StatTile: View {
    var value: String
    var label: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(CoachTheme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CoachTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 72)
        .background(CoachTheme.surfaceStrong.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
