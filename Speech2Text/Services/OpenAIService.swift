import Foundation

// Service for handling OpenAI API communications
class OpenAIService {
    private let apiKey: String
    private let baseURL = URL(string: "https://api.openai.com/v1/")!
    
    init() {
        self.apiKey = APIConfig.openAIKey
    }
    
    func transcribeAudio(fileURL: URL, language: String = "en", completion: @escaping (Result<String, AppError>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.failure(.missingAPIKey))
            return
        }
        
        // Convert to Data
        do {
            let audioData = try Data(contentsOf: fileURL)
            let boundary = UUID().uuidString
            
            var request = URLRequest(url: baseURL.appendingPathComponent("audio/transcriptions"))
            request.httpMethod = "POST"
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            // Create multipart form data
            var body = Data()
            
            // Add file
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"recording.m4a\"\r\n")
            body.append("Content-Type: audio/m4a\r\n\r\n")
            body.append(audioData)
            body.append("\r\n")
            
            // Add model
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
            body.append(ModelConfig.transcriptionModel)
            body.append("\r\n")
            
            // Add language if provided
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n")
            body.append(language)
            body.append("\r\n")
            
            // Add response format
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n")
            body.append("text")
            body.append("\r\n")
            
            // Close the boundary
            body.append("--\(boundary)--\r\n")
            
            request.httpBody = body
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(.networkError(error.localizedDescription)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(.networkError("Invalid response")))
                    return
                }
                
                guard httpResponse.statusCode == 200, let data = data else {
                    let errorMessage = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown error"
                    completion(.failure(.transcriptionError("\(httpResponse.statusCode): \(errorMessage)")))
                    return
                }
                
                // For text response format, the response is just plain text
                if let text = String(data: data, encoding: .utf8) {
                    completion(.success(text))
                } else {
                    completion(.failure(.transcriptionError("Could not decode response")))
                }
            }
            
            task.resume()
        } catch {
            completion(.failure(.recordingError("Failed to read audio file: \(error.localizedDescription)")))
        }
    }
    
    func chatCompletion(messages: [ChatMessage], completion: @escaping (Result<String, AppError>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.failure(.missingAPIKey))
            return
        }
        
        let url = baseURL.appendingPathComponent("chat/completions")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let chatRequest = ChatCompletionRequest(
            model: ModelConfig.llmModel,
            messages: messages
        )
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(chatRequest)
        } catch {
            completion(.failure(.processingError("Failed to encode request: \(error.localizedDescription)")))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error.localizedDescription)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.networkError("Invalid response")))
                return
            }
            
            guard httpResponse.statusCode == 200, let data = data else {
                let errorMessage = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown error"
                completion(.failure(.processingError("\(httpResponse.statusCode): \(errorMessage)")))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(ChatCompletionResponse.self, from: data)
                
                if let choice = result.choices.first, let content = choice.message.content {
                    completion(.success(content))
                } else {
                    completion(.failure(.processingError("No response content")))
                }
            } catch {
                completion(.failure(.processingError("Failed to decode response: \(error.localizedDescription)")))
            }
        }
        
        task.resume()
    }
    
    func translateText(text: String, targetLanguage: String, completion: @escaping (Result<String, AppError>) -> Void) {
        let messages = [
            ChatMessage(role: .system, content: "You are a helpful translation assistant."),
            ChatMessage(role: .user, content: "Translate the following text to \(targetLanguage):\n\n\(text)")
        ]
        
        chatCompletion(messages: messages, completion: completion)
    }
    
    func improveText(text: String, completion: @escaping (Result<String, AppError>) -> Void) {
        let messages = [
            ChatMessage(role: .system, content: "You are a writing improvement assistant. Please improve the following text by correcting grammar, enhancing clarity, and making it more coherent while maintaining the original meaning."),
            ChatMessage(role: .user, content: text)
        ]
        
        chatCompletion(messages: messages, completion: completion)
    }
}
