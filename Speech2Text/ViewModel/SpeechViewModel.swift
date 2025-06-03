import Foundation
import SwiftUI  // Added for withAnimation
import UIKit    // Added for UIPasteboard

class SpeechViewModel: ObservableObject {
    @Published var speechText = SpeechText()
    @Published var isProcessing = false
    @Published var isRecording = false
    @Published var errorMessage: String?
    @Published var selectedLanguage: Language
    @Published var showCopySuccess = false
    @Published var temperature: Double {
        didSet {
            UserDefaults.standard.set(temperature, forKey: "temperature")
        }
    }
    @Published var customCorrections: [String: String] = [:]
    
    let supportedLanguages = [
        Language(name: "English", code: "en"),
        Language(name: "Spanish", code: "es"),
        Language(name: "French", code: "fr"),
        Language(name: "German", code: "de"),
        Language(name: "Chinese", code: "zh"),
        Language(name: "Japanese", code: "ja"),
        Language(name: "Korean", code: "ko"),
        Language(name: "Russian", code: "ru"),
        Language(name: "Arabic", code: "ar"),
        Language(name: "Hindi", code: "hi")
    ]
    
    // Make audioService accessible to the view for waveform visualization
    let audioService = AudioService()
    
    private let openAIService = OpenAIService()
    private let correctionManager = CorrectionManager.shared
    
    init() {
        // Default language is English
        selectedLanguage = supportedLanguages[0]
        temperature = UserDefaults.standard.object(forKey: "temperature") as? Double ?? 0.7
        
        // Load user-defined corrections
        customCorrections = correctionManager.corrections
        correctionManager.$corrections.assign(to: &$customCorrections)
        
        // Bind to audio service recording state
        audioService.$isRecording
            .assign(to: &$isRecording)
        
        // Handle errors from audio service
        audioService.$error
            .compactMap { $0?.description }
            .assign(to: &$errorMessage)
    }
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        errorMessage = nil
        audioService.startRecording()
    }
    
    private func stopRecording() {
        isProcessing = true

        guard let audioFileURL = audioService.stopRecording() else {
            errorMessage = "Failed to get recording file" // [cite: 100]
            isProcessing = false
            return
        }

        // Transcribe the audio
        openAIService.transcribeAudio(fileURL: audioFileURL) { [weak self] result in // [cite: 100]
            guard let self = self else { return } // [cite: 101]

            DispatchQueue.main.async {
                self.isProcessing = false

                switch result {
                case .success(let transcribedText):
                    // Apply the correction here
                    let correctedText = self.correctCommonMistranscriptions(text: transcribedText)
                    self.speechText.originalText = correctedText // [cite: 102]
                case .failure(let error):
                    self.errorMessage = error.description // [cite: 102]
                }
            }
        }
    }
    
    func translateText() {
        guard !speechText.originalText.isEmpty else {
            errorMessage = "No text to translate"
            return
        }

        isProcessing = true // [cite: 104]
        errorMessage = nil // [cite: 104]

        openAIService.translateText(
            text: speechText.originalText,
            targetLanguageName: selectedLanguage.name, // Pass the name for general display if needed by prompt
            targetLanguageCode: selectedLanguage.code,  // Pass the code for specific logic
            temperature: temperature // [cite: 104]
        ) { [weak self] result in // [cite: 104]
            guard let self = self else { return } // [cite: 105]

            DispatchQueue.main.async {
                self.isProcessing = false // [cite: 105]
                switch result { // [cite: 106]
                case .success(let translatedText): // [cite: 106]
                    self.speechText.processedText = translatedText // [cite: 106]
                case .failure(let error): // [cite: 106]
                    self.errorMessage = error.description // [cite: 107]
                }
            }
        }
    }

    func improveText() {
        guard !speechText.originalText.isEmpty else {
            errorMessage = "No text to improve"
            return
        }

        isProcessing = true // [cite: 108]
        errorMessage = nil // [cite: 108]

        // Assuming selectedLanguage reflects the language of originalText for improvement purposes.
        // If originalText could be a different language than selectedLanguage (e.g., after translation),
        // you might need a more sophisticated way to determine originalTextLanguageCode.
        // For now, we use selectedLanguage.code.
        openAIService.improveText(
            text: speechText.originalText,
            originalTextLanguageCode: selectedLanguage.code,
            temperature: temperature // [cite: 108]
        ) { [weak self] result in // [cite: 108]
            guard let self = self else { return } // [cite: 109]

            DispatchQueue.main.async {
                self.isProcessing = false // [cite: 109]
                switch result { // [cite: 109]
                case .success(let improvedText): // [cite: 110]
                    self.speechText.processedText = improvedText // [cite: 110]
                case .failure(let error): // [cite: 110]
                    self.errorMessage = error.description // [cite: 111]
                }
            }
        }
    }
    
    // Function to clear both text boxes
    func clearText() {
        speechText.originalText = ""
        speechText.processedText = ""
    }
    
    // Function to replace the original text with the processed text
    func replaceText() {
        let tempText = speechText.originalText
        speechText.originalText = speechText.processedText
        speechText.processedText = tempText
    }
    
    // Function to copy the processed text to clipboard
    func copyProcessedText() {
        guard !speechText.processedText.isEmpty else {
            errorMessage = "No text to copy"
            return
        }
        
        UIPasteboard.general.string = speechText.processedText
        
        // Show success message
        withAnimation {
            showCopySuccess = true
        }
        
        // Hide the message after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            withAnimation {
                self?.showCopySuccess = false
            }
        }
    }

    // MARK: - User Corrections Management
    
    func addCorrection(incorrect: String, correct: String) {
        correctionManager.addCorrection(incorrect: incorrect, correct: correct)
    }

    func removeCorrection(for incorrect: String) {
        correctionManager.removeCorrection(for: incorrect)
    }

    private func correctCommonMistranscriptions(text: String) -> String {
        var correctedText = text
        for (incorrect, correct) in customCorrections {
            correctedText = correctedText.replacingOccurrences(of: incorrect, with: correct)
        }
        return correctedText
    }
}
