import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
final class ExerciseImageViewModel: ObservableObject {
    @Published private(set) var image: UIImage?
    @Published private(set) var isLoading = false
    @Published private(set) var didFail = false
    @Published private(set) var statusMessage = "Generated exercise image"

    private let generationService: OpenAIExerciseImageGenerationService
    private let cacheService: ExerciseImageCacheService

    init(
        generationService: OpenAIExerciseImageGenerationService = OpenAIExerciseImageGenerationService(),
        cacheService: ExerciseImageCacheService = ExerciseImageCacheService()
    ) {
        self.generationService = generationService
        self.cacheService = cacheService
    }

    func load(for exercise: Exercise) async {
        let cacheKey = cacheService.cacheKey(for: exercise.name)

        if cacheService.imageExists(exerciseId: cacheKey),
           let cachedImage = cacheService.loadCachedImage(exerciseId: cacheKey) {
            image = cachedImage
            isLoading = false
            didFail = false
            statusMessage = "Cached generated image"
            return
        }

        isLoading = true
        didFail = false
        statusMessage = "Generating image with ChatGPT"

        do {
            let data = try await generationService.generateImage(for: exercise)
            guard let generatedImage = UIImage(data: data) else {
                markFailed()
                return
            }

            cacheService.saveImage(imageData: data, exerciseId: cacheKey)
            image = generatedImage
            isLoading = false
            statusMessage = "Generated image saved"
        } catch {
            markFailed()
        }
    }

    private func markFailed() {
        image = nil
        isLoading = false
        didFail = true
        statusMessage = OpenAIAPIKeyProvider.apiKey == nil ? "Add OPENAI_API_KEY to generate images" : "Image generation failed"
    }
}
