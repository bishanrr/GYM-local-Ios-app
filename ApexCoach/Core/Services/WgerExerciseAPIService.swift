import Foundation

struct WgerExercise: Identifiable, Equatable {
    var id: Int
    var name: String
    var description: String
    var primaryMuscles: [String]
    var secondaryMuscles: [String]
    var equipment: [String]
}

struct WgerExerciseAPIService {
    private let baseURL = URL(string: "https://wger.de/api/v2")!
    private let decoder = JSONDecoder()

    func searchExerciseByName(name: String) async throws -> WgerExercise? {
        for candidate in searchCandidates(for: name) {
            guard let translation = try await fetchTranslation(named: candidate) else { continue }
            return try await fetchExerciseInfo(exerciseId: translation.exercise, fallbackName: translation.name, fallbackDescription: translation.descriptionSource)
        }

        return nil
    }

    func fetchExerciseImages(exerciseId: Int) async throws -> [URL] {
        var components = URLComponents(url: baseURL.appendingPathComponent("exerciseimage/"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "exercise", value: "\(exerciseId)"),
            URLQueryItem(name: "format", value: "json")
        ]

        let response: WgerImageResponse = try await fetch(components.url!)
        return response.results
            .sorted { lhs, rhs in lhs.isMain && !rhs.isMain }
            .compactMap { makeAbsoluteURL(from: $0.image) }
    }

    private func fetchTranslation(named name: String) async throws -> WgerTranslationResult? {
        var components = URLComponents(url: baseURL.appendingPathComponent("exercise-translation/"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "language", value: "2"),
            URLQueryItem(name: "name", value: name),
            URLQueryItem(name: "limit", value: "10"),
            URLQueryItem(name: "format", value: "json")
        ]

        let response: WgerTranslationResponse = try await fetch(components.url!)
        let normalizedTarget = name.normalizedExerciseName
        return response.results.first { $0.name.normalizedExerciseName == normalizedTarget } ?? response.results.first
    }

    private func fetchExerciseInfo(exerciseId: Int, fallbackName: String, fallbackDescription: String) async throws -> WgerExercise {
        let url = baseURL.appendingPathComponent("exerciseinfo/\(exerciseId)/")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "format", value: "json")]

        let detail: WgerExerciseInfoResponse = try await fetch(components.url!)
        let englishTranslation = detail.translations.first { $0.language == 2 } ?? detail.translations.first

        return WgerExercise(
            id: detail.id,
            name: englishTranslation?.name ?? fallbackName,
            description: (englishTranslation?.descriptionSource ?? fallbackDescription).cleanedWgerText,
            primaryMuscles: detail.muscles.map(\.displayName),
            secondaryMuscles: detail.secondaryMuscles.map(\.displayName),
            equipment: detail.equipment.map(\.name)
        )
    }

    private func fetch<T: Decodable>(_ url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        request.setValue("ApexCoach iOS", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw WgerAPIError.invalidResponse
        }

        return try decoder.decode(T.self, from: data)
    }

    private func makeAbsoluteURL(from value: String) -> URL? {
        if let url = URL(string: value), url.scheme != nil {
            return url
        }
        return URL(string: "https://wger.de\(value)")
    }

    private func searchCandidates(for name: String) -> [String] {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let simplified = trimmed
            .replacingOccurrences(of: "Barbell ", with: "")
            .replacingOccurrences(of: "Dumbbell ", with: "")
            .replacingOccurrences(of: "Machine ", with: "")
            .replacingOccurrences(of: "Seated ", with: "")
            .replacingOccurrences(of: "One-Arm ", with: "")
            .replacingOccurrences(of: "Assisted ", with: "")
            .replacingOccurrences(of: "Incline ", with: "")

        let aliases: [String: [String]] = [
            "Dumbbell Bench Press": ["Bench Press"],
            "Barbell Bench Press": ["Bench Press"],
            "Machine Chest Press": ["Chest Press", "Bench Press"],
            "One-Arm Dumbbell Row": ["Dumbbell Row", "Row"],
            "Seated Cable Row": ["Cable Row", "Row"],
            "Lat Pulldown": ["Lat Pull-down", "Pull-down"],
            "Dumbbell Shoulder Press": ["Shoulder Press", "Overhead Press"],
            "Lateral Raise": ["Side Lateral Raise"],
            "Goblet Squat": ["Squat"],
            "Barbell Back Squat": ["Squat"],
            "Romanian Deadlift": ["Deadlift"],
            "Walking Lunge": ["Lunge"],
            "Calf Raise": ["Standing Calf Raise"],
            "Plank": ["Front Plank"]
        ]

        var values = [trimmed, simplified]
        values.append(contentsOf: aliases[trimmed] ?? [])
        return Array(NSOrderedSet(array: values)).compactMap { $0 as? String }.filter { !$0.isEmpty }
    }
}

enum WgerAPIError: Error {
    case invalidResponse
}

private struct WgerTranslationResponse: Decodable {
    var results: [WgerTranslationResult]
}

private struct WgerTranslationResult: Decodable {
    var name: String
    var exercise: Int
    var descriptionSource: String

    enum CodingKeys: String, CodingKey {
        case name
        case exercise
        case descriptionSource = "description_source"
    }
}

private struct WgerExerciseInfoResponse: Decodable {
    var id: Int
    var muscles: [WgerMuscle]
    var secondaryMuscles: [WgerMuscle]
    var equipment: [WgerEquipment]
    var translations: [WgerInfoTranslation]

    enum CodingKeys: String, CodingKey {
        case id
        case muscles
        case secondaryMuscles = "muscles_secondary"
        case equipment
        case translations
    }
}

private struct WgerInfoTranslation: Decodable {
    var name: String
    var descriptionSource: String
    var language: Int

    enum CodingKeys: String, CodingKey {
        case name
        case descriptionSource = "description_source"
        case language
    }
}

private struct WgerMuscle: Decodable {
    var name: String
    var englishName: String?

    enum CodingKeys: String, CodingKey {
        case name
        case englishName = "name_en"
    }

    var displayName: String {
        guard let englishName, !englishName.isEmpty else { return name }
        return englishName
    }
}

private struct WgerEquipment: Decodable {
    var name: String
}

private struct WgerImageResponse: Decodable {
    var results: [WgerImageResult]
}

private struct WgerImageResult: Decodable {
    var image: String
    var isMain: Bool

    enum CodingKeys: String, CodingKey {
        case image
        case isMain = "is_main"
    }
}

private extension String {
    var normalizedExerciseName: String {
        lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var cleanedWgerText: String {
        replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
