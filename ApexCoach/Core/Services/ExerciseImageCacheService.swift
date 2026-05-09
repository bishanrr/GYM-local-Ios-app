import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
typealias UIImage = NSImage
#endif

final class ExerciseImageCacheService {
    private let directoryURL: URL

    init(directoryURL: URL? = nil) {
        if let directoryURL {
            self.directoryURL = directoryURL
        } else {
            self.directoryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("ApexCoach/ExerciseImages", isDirectory: true)
        }

        try? FileManager.default.createDirectory(at: self.directoryURL, withIntermediateDirectories: true)
    }

    func saveImage(imageData: Data, exerciseId: String) {
        try? imageData.write(to: imageURL(for: exerciseId), options: [.atomic])
    }

    func loadCachedImage(exerciseId: String) -> UIImage? {
        guard let data = try? Data(contentsOf: imageURL(for: exerciseId)) else { return nil }
        return UIImage(data: data)
    }

    func imageExists(exerciseId: String) -> Bool {
        FileManager.default.fileExists(atPath: imageURL(for: exerciseId).path)
    }

    func cacheKey(for exerciseName: String) -> String {
        exerciseName
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }

    private func imageURL(for exerciseId: String) -> URL {
        directoryURL.appendingPathComponent(safeFileName(for: exerciseId)).appendingPathExtension("png")
    }

    private func safeFileName(for value: String) -> String {
        value
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }
}
