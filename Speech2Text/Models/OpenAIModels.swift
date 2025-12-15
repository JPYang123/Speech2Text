import Foundation

// MARK: - OpenAI Request/Response Models

struct AudioFile {
    let data: Data
    let filename: String
}

struct AudioTranscriptionQuery {
    let file: AudioFile
    let model: String
    let language: String?
}

struct AudioTranscriptionResult: Decodable {
    let text: String
}

enum ChatRole: String, Codable {
    case system
    case user
    case assistant
}

struct ChatMessage: Codable {
    let role: ChatRole
    let content: String
}

struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double?
}

struct ChatCompletionResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let role: String
            let content: String?
        }
        let message: Message
        let index: Int
    }

    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
}
