import Foundation
import NaturalLanguage

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

    /// Transcribe audio and detect the spoken language using OpenAI Whisper.
    /// Returns both the transcribed text and the detected language code.
    func transcribeAudioWithDetection(
        fileURL: URL,
        completion: @escaping (Result<(text: String, language: String), AppError>) -> Void
    ) {
        guard !apiKey.isEmpty else {
            completion(.failure(.missingAPIKey))
            return
        }

        do {
            let audioData = try Data(contentsOf: fileURL)
            let boundary = UUID().uuidString

            var request = URLRequest(url: baseURL.appendingPathComponent("audio/transcriptions"))
            request.httpMethod = "POST"
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

            var body = Data()

            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"recording.m4a\"\r\n")
            body.append("Content-Type: audio/m4a\r\n\r\n")
            body.append(audioData)
            body.append("\r\n")

            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
            body.append(ModelConfig.transcriptionModel)
            body.append("\r\n")

            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n")
            body.append("json")
            body.append("\r\n")

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

                struct TextResponse: Decodable {
                    let text: String
                }

                do {
                    let decoder = JSONDecoder()
                    let result = try decoder.decode(TextResponse.self, from: data)

                    let recognizer = NLLanguageRecognizer()
                    recognizer.processString(result.text)
                    let detectedLanguage = recognizer.dominantLanguage?.rawValue ?? ""

                    completion(.success((result.text, detectedLanguage)))
                } catch {
                    completion(.failure(.transcriptionError("Could not decode response")))
                }
            }

            task.resume()
        } catch {
            completion(.failure(.recordingError("Failed to read audio file: \(error.localizedDescription)")))
        }
    }

    func chatCompletion(
        messages: [ChatMessage],
        temperature: Double = 0.7,
        completion: @escaping (Result<String, AppError>) -> Void
    ) {
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
            messages: messages,
            temperature: temperature
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
    
    func translateText(
        text: String,
        targetLanguageName: String, // e.g., "Chinese"
        targetLanguageCode: String, // e.g., "zh"
        temperature: Double = 1.0,
        completion: @escaping (Result<String, AppError>) -> Void
    ) {
        var finalTargetLanguageDescription = targetLanguageName
        // If the target language is Chinese, specify Simplified Chinese.
        if targetLanguageCode == "zh" { // Assuming "zh" is your code for Chinese [cite: 96]
            finalTargetLanguageDescription = "Simplified Chinese"
        }
        
        let messages = [
            ChatMessage(role: .system, content: "You are a helpful translation assistant."), // [cite: 82]
            ChatMessage(role: .user, content: "Translate the following text to \(finalTargetLanguageDescription):\n\n\(text)") // [cite: 82]
        ]
        
        chatCompletion(messages: messages, temperature: temperature, completion: completion)
    }
    
    func improveText(
        text: String,
        originalTextLanguageCode: String, // e.g., "zh" if the original text is Chinese
        temperature: Double = 1.0, // [cite: 83]
        completion: @escaping (Result<String, AppError>) -> Void
    ) {
        var systemPrompt = "You are an assistant designed to enhance writing. Please revise the following text by correcting grammar, improving clarity, and ensuring coherence, while preserving the original meaning." // [cite: 84]
        
        // If the original text is in Chinese, instruct the LLM to output in Simplified Chinese.
        if originalTextLanguageCode == "zh" {
            systemPrompt += " Ensure the improved text is in Simplified Chinese."
        }
        
        let messages = [
            ChatMessage(role: .system, content: systemPrompt),
            ChatMessage(role: .user, content: text) // [cite: 84]
        ]
        
        chatCompletion(messages: messages, temperature: temperature, completion: completion)
    }

    /// Generate speech audio for the given text using OpenAI TTS.
    /// - Returns: URL to a temporary audio file on success.
    func generateSpeechAudio(
        text: String,
        voice: String,
        completion: @escaping (Result<URL, AppError>) -> Void
    ) {
        guard !apiKey.isEmpty else {
            completion(.failure(.missingAPIKey))
            return
        }

        let url = baseURL.appendingPathComponent("audio/speech")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": ModelConfig.ttsModel,
            "input": text,
            "voice": voice,
            "response_format": "aac"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(.processingError("Failed to encode request")))
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
                let msg = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown error"
                completion(.failure(.networkError("\(httpResponse.statusCode): \(msg)")))
                return
            }

            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("openai_tts.aac")
            do {
                try data.write(to: tempURL)
                completion(.success(tempURL))
            } catch {
                completion(.failure(.processingError("Failed to save audio")))
            }
        }

        task.resume()
    }
}
