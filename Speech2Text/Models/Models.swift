import Foundation
import SwiftUI

// MARK: - API Keys configuration

struct APIConfig {
    static let openAIKeyIdentifier = "OpenAIAPIKey"

    /// Resolution order:
    /// 1) Environment variable OPENAI_API_KEY (dev / CI)
    /// 2) Keychain
    /// 3) Legacy UserDefaults (migrate once)
    static var openAIKey: String {
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return envKey
        }

        if let key = KeychainStore.loadString(forKey: openAIKeyIdentifier), !key.isEmpty {
            return key
        }

        // Legacy fallback + migration
        if let legacy = UserDefaults.standard.string(forKey: openAIKeyIdentifier), !legacy.isEmpty {
            try? KeychainStore.saveString(legacy, forKey: openAIKeyIdentifier)
            UserDefaults.standard.removeObject(forKey: openAIKeyIdentifier)
            return legacy
        }

        return ""
    }

    static var hasKey: Bool { !openAIKey.isEmpty }

    static func saveOpenAIKey(_ key: String) throws {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        try KeychainStore.saveString(trimmed, forKey: openAIKeyIdentifier)
        // Clear legacy
        UserDefaults.standard.removeObject(forKey: openAIKeyIdentifier)
    }

    static func clearOpenAIKey() {
        try? KeychainStore.delete(forKey: openAIKeyIdentifier)
        UserDefaults.standard.removeObject(forKey: openAIKeyIdentifier)
    }
}

// MARK: - Model Config

struct ModelConfig {
    static let transcriptionModel = "gpt-4o-mini-transcribe"
    static let llmModel = "gpt-4o-mini"
    static let ttsModel = "gpt-4o-mini-tts"
}

// MARK: - Options

enum TTSOption: String, CaseIterable, Identifiable {
    case openAI
    case apple

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openAI: return ModelConfig.ttsModel
        case .apple: return "Apple Built-in"
        }
    }
}

enum OpenAIVoice: String, CaseIterable, Identifiable {
    case alloy, echo, fable, onyx, nova, shimmer

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

// MARK: - Domain Models

struct Language: Identifiable, Hashable {
    let name: String
    let code: String
    var id: String { code }
}

struct SpeechText {
    var originalText: String = ""
    var processedText: String = ""
}

// MARK: - Errors

enum AppError: Error {
    case recordingError(String)
    case transcriptionError(String)
    case processingError(String)
    case networkError(String)
    case missingAPIKey
    case fileIOError(String)

    var description: String {
        switch self {
        case .recordingError(let message): return "Recording error: \(message)"
        case .transcriptionError(let message): return "Transcription error: \(message)"
        case .processingError(let message): return "Processing error: \(message)"
        case .networkError(let message): return "Network error: \(message)"
        case .missingAPIKey: return "OpenAI API key is missing. Please set it in Settings."
        case .fileIOError(let message): return "File error: \(message)"
        }
    }
}
