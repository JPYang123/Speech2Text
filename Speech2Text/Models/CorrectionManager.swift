import Foundation

// Manager for user-defined word corrections
class CorrectionManager: ObservableObject {
    static let shared = CorrectionManager()
    @Published private(set) var corrections: [String: String] = [:]
    @Published var error: AppError?
    
    private let fileName = "UserCorrections.json"

    private init() {
        loadCorrections()
    }

    private var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(fileName)
    }

    // Load corrections from the JSON file
    func loadCorrections() {
        self.error = nil
        do {
            let data = try Data(contentsOf: fileURL)
            corrections = try JSONDecoder().decode([String: String].self, from: data)
        } catch {
            corrections = [:]
            if FileManager.default.fileExists(atPath: fileURL.path) {
                self.error = .fileIOError("Failed to load corrections: \(error.localizedDescription)")
            }
        }
    }

    // Save corrections to the JSON file
    func saveCorrections() {
        self.error = nil
        do {
            let data = try JSONEncoder().encode(corrections)
            try data.write(to: fileURL)
        } catch {
            self.error = .fileIOError("Failed to save corrections: \(error.localizedDescription)")
        }
    }

    // Add or update a correction pair
    func addCorrection(incorrect: String, correct: String) {
        guard !incorrect.isEmpty else { return }
        corrections[incorrect] = correct
        saveCorrections()
    }

    // Remove a correction pair
    func removeCorrection(for incorrect: String) {
        corrections.removeValue(forKey: incorrect)
        saveCorrections()
    }
}
