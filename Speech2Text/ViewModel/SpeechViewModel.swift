import Foundation
import SwiftUI  // Added for withAnimation
import UIKit    // Added for UIPasteboard
import AVFoundation

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
    @Published var ttsOption: TTSOption {
         didSet {
             UserDefaults.standard.set(ttsOption.rawValue, forKey: "ttsOption")
         }
     }
    @Published var selectedVoice: OpenAIVoice {
        didSet {
            UserDefaults.standard.set(selectedVoice.rawValue, forKey: "openAIVoice")
        }
    }
    @Published var customCorrections: [String: String] = [:]
    @Published var isInterpreting = false
    
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
        Language(name: "Hindi", code: "hi"),
        Language(name: "Vietnamese", code: "vi"),
        Language(name: "Italian", code: "it"),
        Language(name: "Thai", code: "th"),
        Language(name: "Portuguese", code: "pt"),
        Language(name: "Dutch", code: "nl")
    ]
    
    // Make audioService accessible to the view for waveform visualization
    let audioService = AudioService()
    
    private let openAIService = OpenAIService()
    private let correctionManager = CorrectionManager.shared
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    
    init() {
        // Default language is English
        selectedLanguage = supportedLanguages[0]
        temperature = UserDefaults.standard.object(forKey: "temperature") as? Double ?? 0.7
        if let savedOption = UserDefaults.standard.string(forKey: "ttsOption"),
           let option = TTSOption(rawValue: savedOption) {
            ttsOption = option
        } else {
            ttsOption = .apple
        }
        if let savedVoice = UserDefaults.standard.string(forKey: "openAIVoice"),
           let voice = OpenAIVoice(rawValue: savedVoice) {
            selectedVoice = voice
        } else {
            selectedVoice = .echo
        }
        
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
        
        // Handle errors from correction manager
        correctionManager.$error
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

    func toggleInterpreter() {
        if isRecording {
            stopInterpreter()
        } else {
            startInterpreter()
        }
    }
    
    private func startRecording() {
        errorMessage = nil
        audioService.startRecording()
    }
 
    private func startInterpreter() {
        errorMessage = nil
        isInterpreting = true
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
                    // Apply the correction here
                    let correctedText = self.correctCommonMistranscriptions(text: transcribedText)
                    self.speechText.originalText = correctedText
                case .failure(let error):
                    self.errorMessage = error.description
                }
            }
        }
    }
 
    private func stopInterpreter() {
        isProcessing = true

        guard let audioFileURL = audioService.stopRecording() else {
            errorMessage = "Failed to get recording file"
            isProcessing = false
            isInterpreting = false
            return
        }

        openAIService.transcribeAudioWithDetection(fileURL: audioFileURL) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let output):
                let transcribedText = self.correctCommonMistranscriptions(text: output.text)
                self.speechText.originalText = transcribedText
                self.openAIService.translateText(
                    text: transcribedText,
                    targetLanguageName: self.selectedLanguage.name,
                    targetLanguageCode: self.selectedLanguage.code,
                    temperature: self.temperature
                ) { [weak self] translateResult in
                    DispatchQueue.main.async {
                        self?.isProcessing = false
                        self?.isInterpreting = false
                        switch translateResult {
                        case .success(let translatedText):
                            self?.speechText.processedText = translatedText
                            self?.speakProcessedText()
                        case .failure(let error):
                            self?.errorMessage = error.description
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.isInterpreting = false
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
            targetLanguageName: selectedLanguage.name,
            targetLanguageCode: selectedLanguage.code,
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
            originalTextLanguageCode: selectedLanguage.code,
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

    // Function to speak the processed text using the selected TTS option
    func speakProcessedText() {
        guard !speechText.processedText.isEmpty else {
            errorMessage = "No text to speak"
            return
        }

        switch ttsOption {
        case .apple:
            // Configure audio session for playback before speaking
            configureAudioSessionForPlayback()
            
            let utterance = AVSpeechUtterance(string: speechText.processedText)
            utterance.volume = 1.0
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
            
            // Set voice for the selected language if available
            if let voice = AVSpeechSynthesisVoice(language: selectedLanguage.code) {
                utterance.voice = voice
            }
            
            speechSynthesizer.speak(utterance)
            
        case .openAI:
            // Configure audio session for playback before playing OpenAI audio
            configureAudioSessionForPlayback()
            
            isProcessing = true
            openAIService.generateSpeechAudio(text: speechText.processedText, voice: selectedVoice.rawValue) { [weak self] result in
                DispatchQueue.main.async {
                    self?.isProcessing = false
                    switch result {
                    case .success(let url):
                        do {
                            self?.audioPlayer = try AVAudioPlayer(contentsOf: url)
                            self?.audioPlayer?.volume = 1.0
                            self?.audioPlayer?.play()
                        } catch {
                            self?.errorMessage = "Failed to play audio"
                        }
                    case .failure(let error):
                        self?.errorMessage = error.description
                    }
                }
            }
        }
    }
    
    // MARK: - Audio Session Management
    
    private func configureAudioSessionForPlayback() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Set category to playback for maximum volume
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Override output to speaker if needed (for iPhone)
            if audioSession.availableInputs?.first(where: { $0.portType == .builtInMic }) != nil {
                try audioSession.overrideOutputAudioPort(.speaker)
            }
            
        } catch {
            print("Failed to configure audio session for playbook: \(error)")
            // Don't set errorMessage here as TTS might still work with current session
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
