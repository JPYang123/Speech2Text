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
    @Published var temperature: Double = 0.7
    
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
    
    init() {
        // Default language is English
        selectedLanguage = supportedLanguages[0]
        
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
            errorMessage = "Failed to get recording file"
            isProcessing = false
            return
        }
        
        // Transcribe the audio
        openAIService.transcribeAudio(fileURL: audioFileURL) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isProcessing = false
                
                switch result {
                case .success(let transcribedText):
                    self.speechText.originalText = transcribedText
                case .failure(let error):
                    self.errorMessage = error.description
                }
            }
        }
    }
    
    func translateText() {
        guard !speechText.originalText.isEmpty else {
            errorMessage = "No text to translate"
            return
        }
        
        isProcessing = true
        errorMessage = nil
        
        openAIService.translateText(
            text: speechText.originalText,
            targetLanguage: selectedLanguage.name,
            temperature: temperature
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isProcessing = false
                
                switch result {
                case .success(let translatedText):
                    self.speechText.processedText = translatedText
                case .failure(let error):
                    self.errorMessage = error.description
                }
            }
        }
    }
    
    func improveText() {
        guard !speechText.originalText.isEmpty else {
            errorMessage = "No text to improve"
            return
        }
        
        isProcessing = true
        errorMessage = nil
        
        openAIService.improveText(
            text: speechText.originalText,
            temperature: temperature
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isProcessing = false
                
                switch result {
                case .success(let improvedText):
                    self.speechText.processedText = improvedText
                case .failure(let error):
                    self.errorMessage = error.description
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
        speechText.originalText = speechText.processedText
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
}
