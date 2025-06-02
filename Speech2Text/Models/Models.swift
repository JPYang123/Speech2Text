// MARK: - Models

import Foundation
import AVFoundation
import SwiftUI

// API Keys configuration
struct APIConfig {
    // For a real app, you'd want to store this securely
    static var openAIKey: String {
        // Prefer an environment variable so the key isn't stored in source control
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            return envKey
        }
        
        // Fall back to a key the user saved in UserDefaults via the settings UI
        if let savedKey = UserDefaults.standard.string(forKey: "OpenAIAPIKey") {
            return savedKey
        }

        // No key available
        return ""
    }
}

// Configuration for the OpenAI models
struct ModelConfig {
    static let transcriptionModel = "gpt-4o-mini-transcribe"
    static let llmModel = "gpt-4o-mini"
}

// Language model for translation
struct Language: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let code: String
}

// Models related to speech and text functionality
struct SpeechText {
    var originalText: String = ""
    var processedText: String = ""
}

// Error model
enum AppError: Error {
    case recordingError(String)
    case transcriptionError(String)
    case processingError(String)
    case networkError(String)
    case missingAPIKey
    
    var description: String {
        switch self {
        case .recordingError(let message): return "Recording error: \(message)"
        case .transcriptionError(let message): return "Transcription error: \(message)"
        case .processingError(let message): return "Processing error: \(message)"
        case .networkError(let message): return "Network error: \(message)"
        case .missingAPIKey: return "OpenAI API key is missing. Please set it in your app."
        }
    }
}
