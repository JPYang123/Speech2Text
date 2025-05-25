// MARK: - Models

import Foundation
import AVFoundation
import SwiftUI

// API Keys configuration
struct APIConfig {
    // For a real app, you'd want to store this securely
    static var openAIKey: String {
        // First try to get from environment
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            return envKey
        }
        
        // Add your key here for development purposes only
        // Don't include this in production code or source control
        return "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"
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
