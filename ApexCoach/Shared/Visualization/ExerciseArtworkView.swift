import SwiftUI
#if canImport(UIKit)
import UIKit
private typealias ExerciseArtworkPlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
private typealias ExerciseArtworkPlatformImage = NSImage
#endif

enum ExerciseArtworkPresentation {
    case thumbnail
    case hero

    var cornerRadius: CGFloat {
        switch self {
        case .thumbnail:
            return 8
        case .hero:
            return 8
        }
    }
}

struct ExerciseArtworkView: View {
    var exercise: Exercise
    var presentation: ExerciseArtworkPresentation = .thumbnail

    @State private var cachedImage: ExerciseArtworkPlatformImage?
    private let cacheService = ExerciseImageCacheService()

    var body: some View {
        ZStack {
            if let cachedImage {
                PlatformGeneratedExerciseImage(image: cachedImage, presentation: presentation)
            } else {
                fallbackArtwork
            }
        }
        .background(CoachTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: presentation.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: presentation.cornerRadius, style: .continuous)
                .stroke(CoachTheme.stroke, lineWidth: 1)
        )
        .onAppear(perform: loadCachedImage)
        .task(id: exercise.id) {
            loadCachedImage()
        }
    }

    @ViewBuilder
    private var fallbackArtwork: some View {
        switch presentation {
        case .thumbnail:
            WorkoutThumbnail(
                primaryMuscles: exercise.primaryMuscles,
                secondaryMuscles: exercise.secondaryMuscles,
                phase: exercise.phase
            )
        case .hero:
            HeroMuscleFigure(
                primaryMuscles: exercise.primaryMuscles,
                secondaryMuscles: exercise.secondaryMuscles,
                pose: exercise.primaryMuscles.contains(.chest) ? .bench : .standing
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    private func loadCachedImage() {
        let cacheKey = cacheService.cacheKey(for: exercise.name)
        cachedImage = cacheService.loadCachedImage(exerciseId: cacheKey)
    }
}

private struct PlatformGeneratedExerciseImage: View {
    var image: ExerciseArtworkPlatformImage
    var presentation: ExerciseArtworkPresentation

    var body: some View {
        #if canImport(UIKit)
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: presentation == .thumbnail ? .fill : .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(presentation == .thumbnail ? 0 : 12)
            .clipped()
        #elseif canImport(AppKit)
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: presentation == .thumbnail ? .fill : .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(presentation == .thumbnail ? 0 : 12)
            .clipped()
        #else
        EmptyView()
        #endif
    }
}
