import Foundation

// Audio file structure
struct AudioFile {
    let data: Data
    let filename: String
}

// Audio transcription request parameters
struct AudioTranscriptionQuery {
    let file: AudioFile
    let model: String
    let language: String?
}

// Audio transcription result
struct AudioTranscriptionResult: Decodable {
    let text: String
}

// Chat role
enum ChatRole: String, Codable {
    case system
    case user
    case assistant
}

// Chat message
struct ChatMessage: Codable {
    let role: ChatRole
    let content: String
}

// Chat completion request
struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double? 
}

// Chat completion response
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
