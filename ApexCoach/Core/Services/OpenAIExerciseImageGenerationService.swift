import Foundation

struct OpenAIExerciseImageGenerationService {
    private let endpoint = URL(string: "https://api.openai.com/v1/images/generations")!
    private let apiKey: String?
    private let models: [String]
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(
        apiKey: String? = OpenAIAPIKeyProvider.apiKey,
        models: [String] = ["gpt-image-1.5", "gpt-image-1"]
    ) {
        self.apiKey = apiKey
        self.models = models
    }

    func generateImage(for exercise: Exercise) async throws -> Data {
        guard let apiKey, !apiKey.isEmpty else {
            throw OpenAIImageGenerationError.missingAPIKey
        }

        var lastError: Error?
        for model in models {
            do {
                return try await generateImage(for: exercise, apiKey: apiKey, model: model)
            } catch {
                lastError = error
            }
        }

        throw lastError ?? OpenAIImageGenerationError.missingImageData
    }

    private func generateImage(for exercise: Exercise, apiKey: String, model: String) async throws -> Data {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 90
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(
            OpenAIImageGenerationRequest(
                model: model,
                prompt: prompt(for: exercise)
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw OpenAIImageGenerationError.invalidResponse
        }

        let generated = try decoder.decode(OpenAIImageGenerationResponse.self, from: data)
        guard let base64 = generated.data.first?.base64JSON,
              let imageData = Data(base64Encoded: base64) else {
            throw OpenAIImageGenerationError.missingImageData
        }

        return imageData
    }

    private func prompt(for exercise: Exercise) -> String {
        let primary = exercise.primaryMuscles.map(\.rawValue).joined(separator: ", ")
        let secondary = exercise.secondaryMuscles.map(\.rawValue).joined(separator: ", ")
        let equipment = exercise.equipment.map(\.rawValue).joined(separator: ", ")

        return """
        Create a premium fitness app exercise illustration for "\(exercise.name)".
        Style: consistent Train Co Pilot inspired dark-mode workout artwork, realistic athletic figure, cinematic black background, clean high-contrast lighting, no text, no logos, no watermark.
        Pose: clearly show the exercise movement in a single static image, centered composition, full body or upper body as appropriate.
        Highlight activated muscles with subtle orange-red glow.
        Primary muscles: \(primary.isEmpty ? "target muscles" : primary).
        Secondary muscles: \(secondary.isEmpty ? "supporting muscles" : secondary).
        Equipment: \(equipment.isEmpty ? "as needed for the movement" : equipment).
        Output should look consistent with a premium native iOS workout app.
        """
    }
}

enum OpenAIImageGenerationError: Error {
    case missingAPIKey
    case invalidResponse
    case missingImageData
}

enum OpenAIAPIKeyProvider {
    static var apiKey: String? {
        let infoValue = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String
        let environmentValue = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
        let value = infoValue?.isEmpty == false ? infoValue : environmentValue

        guard let value,
              !value.isEmpty,
              !value.hasPrefix("$(") else {
            return nil
        }

        return value
    }
}

private struct OpenAIImageGenerationRequest: Encodable {
    var model: String
    var prompt: String
    var size = "1024x1024"
    var quality = "medium"
    var n = 1
}

private struct OpenAIImageGenerationResponse: Decodable {
    var data: [OpenAIImageData]
}

private struct OpenAIImageData: Decodable {
    var base64JSON: String?

    enum CodingKeys: String, CodingKey {
        case base64JSON = "b64_json"
    }
}
