import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
final class ExerciseImageViewModel: ObservableObject {
    @Published private(set) var image: UIImage?
    @Published private(set) var remoteExercise: WgerExercise?
    @Published private(set) var isLoading = false
    @Published private(set) var didFail = false

    private let apiService: WgerExerciseAPIService
    private let cacheService: ExerciseImageCacheService

    init(
        apiService: WgerExerciseAPIService = WgerExerciseAPIService(),
        cacheService: ExerciseImageCacheService = ExerciseImageCacheService()
    ) {
        self.apiService = apiService
        self.cacheService = cacheService
    }

    func load(for exercise: Exercise) async {
        let cacheKey = cacheService.cacheKey(for: exercise.name)

        if cacheService.imageExists(exerciseId: cacheKey),
           let cachedImage = cacheService.loadCachedImage(exerciseId: cacheKey) {
            image = cachedImage
            isLoading = false
            didFail = false
            return
        }

        isLoading = true
        didFail = false

        do {
            guard let wgerExercise = try await apiService.searchExerciseByName(name: exercise.name) else {
                markFailed()
                return
            }

            remoteExercise = wgerExercise

            guard let imageURL = try await apiService.fetchExerciseImages(exerciseId: wgerExercise.id).first else {
                markFailed()
                return
            }

            let (data, response) = try await URLSession.shared.data(from: imageURL)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode),
                  let downloadedImage = UIImage(data: data) else {
                markFailed()
                return
            }

            cacheService.saveImage(imageData: data, exerciseId: cacheKey)
            cacheService.saveImage(imageData: data, exerciseId: "\(wgerExercise.id)")
            image = downloadedImage
            isLoading = false
        } catch {
            markFailed()
        }
    }

    private func markFailed() {
        image = nil
        isLoading = false
        didFail = true
    }
}
