import Foundation

actor LocalWorkoutStore {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileURL: URL? = nil) {
        let baseURL = fileURL?.deletingLastPathComponent()
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("ApexCoach", isDirectory: true)

        try? FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        self.fileURL = fileURL ?? baseURL.appendingPathComponent("snapshot.json")

        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func loadSnapshot() throws -> AppSnapshot {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return AppSnapshot()
        }

        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(AppSnapshot.self, from: data)
    }

    func saveSnapshot(_ snapshot: AppSnapshot) throws {
        let data = try encoder.encode(snapshot)
        try data.write(to: fileURL, options: [.atomic])
    }
}
