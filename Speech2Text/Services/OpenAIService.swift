import Foundation
import NaturalLanguage

protocol OpenAIServing {
    func transcribeAudio(fileURL: URL, language: String) async throws -> String
    func transcribeAudioWithDetection(fileURL: URL) async throws -> (text: String, language: String)

    func chatCompletion(messages: [ChatMessage], temperature: Double) async throws -> String
    func translateText(text: String, targetLanguageName: String, targetLanguageCode: String, temperature: Double) async throws -> String
    func improveText(text: String, originalTextLanguageCode: String, temperature: Double) async throws -> String

    func generateSpeechAudio(text: String, voice: String) async throws -> URL
}

final class OpenAIService: OpenAIServing {
    private let baseURL = URL(string: "https://api.openai.com/v1")!

    init() {}

    // MARK: - Public

    func transcribeAudio(fileURL: URL, language: String = "en") async throws -> String {
        try ensureAPIKey()

        let audioData = try await loadFileDataOffMainThread(fileURL)

        let boundary = UUID().uuidString
        var request = URLRequest(url: baseURL.appendingPathComponent("audio/transcriptions"))
        request.httpMethod = "POST"
        request.addValue("Bearer \(APIConfig.openAIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var fields: [String: String] = [
            "model": ModelConfig.transcriptionModel,
            "response_format": "text"
        ]
        if !language.isEmpty {
            fields["language"] = language
        }

        request.httpBody = makeMultipartBody(
            boundary: boundary,
            fields: fields,
            fileFieldName: "file",
            fileName: "recording.m4a",
            mimeType: "audio/m4a",
            fileData: audioData
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTP(response: response, data: data, context: "transcribeAudio")

        guard let text = String(data: data, encoding: .utf8) else {
            throw AppError.transcriptionError("Could not decode transcription response.")
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func transcribeAudioWithDetection(fileURL: URL) async throws -> (text: String, language: String) {
        try ensureAPIKey()

        let audioData = try await loadFileDataOffMainThread(fileURL)

        let boundary = UUID().uuidString
        var request = URLRequest(url: baseURL.appendingPathComponent("audio/transcriptions"))
        request.httpMethod = "POST"
        request.addValue("Bearer \(APIConfig.openAIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let fields: [String: String] = [
            "model": ModelConfig.transcriptionModel,
            "response_format": "json"
        ]

        request.httpBody = makeMultipartBody(
            boundary: boundary,
            fields: fields,
            fileFieldName: "file",
            fileName: "recording.m4a",
            mimeType: "audio/m4a",
            fileData: audioData
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTP(response: response, data: data, context: "transcribeAudioWithDetection")

        struct TextResponse: Decodable { let text: String }
        let decoded = try JSONDecoder().decode(TextResponse.self, from: data)

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(decoded.text)
        let detectedLanguage = recognizer.dominantLanguage?.rawValue ?? ""

        return (decoded.text, detectedLanguage)
    }

    func chatCompletion(messages: [ChatMessage], temperature: Double = 0.7) async throws -> String {
        try ensureAPIKey()

        var request = URLRequest(url: baseURL.appendingPathComponent("chat/completions"))
        request.httpMethod = "POST"
        request.addValue("Bearer \(APIConfig.openAIKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ChatCompletionRequest(model: ModelConfig.llmModel, messages: messages, temperature: temperature)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTP(response: response, data: data, context: "chatCompletion")

        let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw AppError.processingError("No response content.")
        }
        return content
    }

    func translateText(
        text: String,
        targetLanguageName: String,
        targetLanguageCode: String,
        temperature: Double = 1.0
    ) async throws -> String {
        var finalTargetLanguageDescription = targetLanguageName
        if targetLanguageCode == "zh" {
            finalTargetLanguageDescription = "Simplified Chinese"
        }

        let messages = [
            ChatMessage(role: .system, content: "You are a helpful translation assistant."),
            ChatMessage(role: .user, content: "Translate the following text to \(finalTargetLanguageDescription):\n\n\(text)")
        ]

        return try await chatCompletion(messages: messages, temperature: temperature)
    }

    func improveText(
        text: String,
        originalTextLanguageCode: String,
        temperature: Double = 1.0
    ) async throws -> String {
        var systemPrompt = "You are an assistant designed to enhance writing. Please revise the following text by correcting grammar, improving clarity, and ensuring coherence, while preserving the original meaning."
        if originalTextLanguageCode == "zh" {
            systemPrompt += " Ensure the improved text is in Simplified Chinese."
        }

        let messages = [
            ChatMessage(role: .system, content: systemPrompt),
            ChatMessage(role: .user, content: text)
        ]

        return try await chatCompletion(messages: messages, temperature: temperature)
    }

    func generateSpeechAudio(text: String, voice: String) async throws -> URL {
        try ensureAPIKey()

        var request = URLRequest(url: baseURL.appendingPathComponent("audio/speech"))
        request.httpMethod = "POST"
        request.addValue("Bearer \(APIConfig.openAIKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let json: [String: Any] = [
            "model": ModelConfig.ttsModel,
            "input": text,
            "voice": voice,
            "response_format": "aac"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: json)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTP(response: response, data: data, context: "generateSpeechAudio")

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("openai_tts_\(UUID().uuidString).aac")

        do {
            try data.write(to: tempURL, options: [.atomic])
            return tempURL
        } catch {
            throw AppError.processingError("Failed to save audio: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    private func ensureAPIKey() throws {
        guard !APIConfig.openAIKey.isEmpty else {
            throw AppError.missingAPIKey
        }
    }

    private func loadFileDataOffMainThread(_ url: URL) async throws -> Data {
        do {
            return try await Task.detached(priority: .userInitiated) {
                try Data(contentsOf: url)
            }.value
        } catch is CancellationError {
            throw AppError.networkError("Cancelled")
        } catch {
            throw AppError.fileIOError("Failed to read audio file: \(error.localizedDescription)")
        }
    }

    private func validateHTTP(response: URLResponse, data: Data, context: String) throws {
        guard let http = response as? HTTPURLResponse else {
            throw AppError.networkError("\(context): Invalid response.")
        }

        guard (200...299).contains(http.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            // Keep it simple; you can parse structured error JSON later if needed.
            throw AppError.networkError("\(context): \(http.statusCode): \(errorMessage)")
        }
    }

    private func makeMultipartBody(
        boundary: String,
        fields: [String: String],
        fileFieldName: String,
        fileName: String,
        mimeType: String,
        fileData: Data
    ) -> Data {
        var body = Data()

        // File
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(fileFieldName)\"; filename=\"\(fileName)\"\r\n")
        body.appendString("Content-Type: \(mimeType)\r\n\r\n")
        body.append(fileData)
        body.appendString("\r\n")

        // Fields
        for (key, value) in fields {
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.appendString(value)
            body.appendString("\r\n")
        }

        body.appendString("--\(boundary)--\r\n")
        return body
    }
}

private extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
