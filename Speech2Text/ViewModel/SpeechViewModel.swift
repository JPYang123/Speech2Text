import Foundation
import SwiftUI
import UIKit
import AVFoundation
import Combine

@MainActor
final class SpeechViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    // MARK: - Published UI State

    @Published var speechText = SpeechText()

    @Published private(set) var isProcessing = false
    @Published private(set) var processingMessage: String = "Processing..."

    @Published private(set) var isRecording = false
    @Published private(set) var isInterpreting = false

    @Published var errorMessage: String?

    @Published var selectedLanguage: Language {
        didSet { lastSpokenLanguageCode = selectedLanguage.code }
    }
    @Published var interpreterLanguageA: Language
    @Published var interpreterLanguageB: Language

    @Published var temperature: Double
    @Published var ttsOption: TTSOption
    @Published var selectedVoice: OpenAIVoice

    @Published var customCorrections: [String: String] = [:]
    @Published var showCopySuccess = false

    // MARK: - Public read-only data

    let supportedLanguages: [Language] = [
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

    // Expose for waveform visualization
    let audioService: AudioService

    // MARK: - Dependencies

    private let openAIService: OpenAIServing
    private let correctionManager: CorrectionManager

    // MARK: - Internals

    private let speechSynthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    private var lastGeneratedSpeechURL: URL?

    private var lastSpokenLanguageCode: String?
    private var currentTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    private enum DefaultsKeys {
        static let temperature = "temperature"
        static let ttsOption = "ttsOption"
        static let openAIVoice = "openAIVoice"
    }

    // MARK: - Init

    /// ⚠️ Important: Don't use `AudioService()` as a default argument when AudioService is `@MainActor`.
    /// Default-arg expressions are evaluated in the caller's (often nonisolated) context.
    init(
        audioService: AudioService? = nil,
        openAIService: OpenAIServing = OpenAIService(),
        correctionManager: CorrectionManager = .shared
    ) {
        self.audioService = audioService ?? AudioService()
        self.openAIService = openAIService
        self.correctionManager = correctionManager

        let defaultLanguage = supportedLanguages[0]
        let pairedLanguage = supportedLanguages.count > 1 ? supportedLanguages[1] : supportedLanguages[0]

        self.selectedLanguage = defaultLanguage
        self.interpreterLanguageA = defaultLanguage
        self.interpreterLanguageB = pairedLanguage
        self.lastSpokenLanguageCode = defaultLanguage.code

        let storedTemp = UserDefaults.standard.object(forKey: DefaultsKeys.temperature) as? Double
        self.temperature = storedTemp ?? 0.7

        if let savedOption = UserDefaults.standard.string(forKey: DefaultsKeys.ttsOption),
           let option = TTSOption(rawValue: savedOption) {
            self.ttsOption = option
        } else {
            self.ttsOption = .apple
        }

        if let savedVoice = UserDefaults.standard.string(forKey: DefaultsKeys.openAIVoice),
           let voice = OpenAIVoice(rawValue: savedVoice) {
            self.selectedVoice = voice
        } else {
            self.selectedVoice = .echo
        }

        super.init()

        bind()
    }

    private func bind() {
        // Corrections
        customCorrections = correctionManager.corrections
        correctionManager.$corrections
            .receive(on: DispatchQueue.main)
            .assign(to: &$customCorrections)

        // Recording state
        audioService.$isRecording
            .receive(on: DispatchQueue.main)
            .assign(to: &$isRecording)

        // Errors
        audioService.$error
            .compactMap { $0?.description }
            .receive(on: DispatchQueue.main)
            .assign(to: &$errorMessage)

        correctionManager.$error
            .compactMap { $0?.description }
            .receive(on: DispatchQueue.main)
            .assign(to: &$errorMessage)

        // Settings persistence (debounced)
        $temperature
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { UserDefaults.standard.set($0, forKey: DefaultsKeys.temperature) }
            .store(in: &cancellables)

        $ttsOption
            .removeDuplicates()
            .sink { UserDefaults.standard.set($0.rawValue, forKey: DefaultsKeys.ttsOption) }
            .store(in: &cancellables)

        $selectedVoice
            .removeDuplicates()
            .sink { UserDefaults.standard.set($0.rawValue, forKey: DefaultsKeys.openAIVoice) }
            .store(in: &cancellables)
    }

    // MARK: - Recording / Interpreter Controls

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
        isInterpreting = false
        audioService.startRecording()
    }

    private func startInterpreter() {
        errorMessage = nil
        isInterpreting = true
        audioService.startRecording()
    }

    private func stopRecording() {
        guard let audioURL = audioService.stopRecording() else {
            errorMessage = "Failed to get recording file"
            return
        }

        runProcessing(message: "Transcribing…") { [weak self] in
            guard let self else { return }
            do {
                let transcribed = try await self.openAIService.transcribeAudio(fileURL: audioURL, language: "en")
                try Task.checkCancellation()

                let corrected = self.correctCommonMistranscriptions(text: transcribed)
                self.speechText.originalText = corrected
            } catch is CancellationError {
                // silent
            } catch let err as AppError {
                self.errorMessage = err.description
            } catch {
                self.errorMessage = AppError.processingError(error.localizedDescription).description
            }

            self.deleteFileIfPossible(audioURL)
        }
    }

    private func stopInterpreter() {
        guard let audioURL = audioService.stopRecording() else {
            errorMessage = "Failed to get recording file"
            isInterpreting = false
            return
        }

        runProcessing(message: "Transcribing…") { [weak self] in
            guard let self else { return }

            do {
                let output = try await self.openAIService.transcribeAudioWithDetection(fileURL: audioURL)
                try Task.checkCancellation()

                let detected = self.normalizedLanguageCode(output.language)
                let targetLanguage = self.interpreterTargetLanguage(for: detected)
                let transcribedText = self.correctCommonMistranscriptions(text: output.text)

                self.speechText.originalText = transcribedText

                self.processingMessage = "Translating…"
                let translated = try await self.openAIService.translateText(
                    text: transcribedText,
                    targetLanguageName: targetLanguage.name,
                    targetLanguageCode: targetLanguage.code,
                    temperature: self.temperature
                )
                try Task.checkCancellation()

                self.speechText.processedText = translated
                self.lastSpokenLanguageCode = targetLanguage.code

                try await self.speakProcessedTextInternal(languageCode: targetLanguage.code)
            } catch is CancellationError {
                // silent
            } catch let err as AppError {
                self.errorMessage = err.description
            } catch {
                self.errorMessage = AppError.processingError(error.localizedDescription).description
            }

            self.isInterpreting = false
            self.deleteFileIfPossible(audioURL)
        }
    }

    // MARK: - Text Actions

    func translateText() {
        guard !speechText.originalText.isEmpty else {
            errorMessage = "No text to translate"
            return
        }

        runProcessing(message: "Translating…") { [weak self] in
            guard let self else { return }
            do {
                let translated = try await self.openAIService.translateText(
                    text: self.speechText.originalText,
                    targetLanguageName: self.selectedLanguage.name,
                    targetLanguageCode: self.selectedLanguage.code,
                    temperature: self.temperature
                )
                try Task.checkCancellation()

                self.speechText.processedText = translated
                self.lastSpokenLanguageCode = self.selectedLanguage.code
            } catch is CancellationError {
                // silent
            } catch let err as AppError {
                self.errorMessage = err.description
            } catch {
                self.errorMessage = AppError.processingError(error.localizedDescription).description
            }
        }
    }

    func improveText() {
        guard !speechText.originalText.isEmpty else {
            errorMessage = "No text to improve"
            return
        }

        runProcessing(message: "Improving…") { [weak self] in
            guard let self else { return }
            do {
                let improved = try await self.openAIService.improveText(
                    text: self.speechText.originalText,
                    originalTextLanguageCode: self.selectedLanguage.code,
                    temperature: self.temperature
                )
                try Task.checkCancellation()

                self.speechText.processedText = improved
                self.lastSpokenLanguageCode = self.selectedLanguage.code
            } catch is CancellationError {
                // silent
            } catch let err as AppError {
                self.errorMessage = err.description
            } catch {
                self.errorMessage = AppError.processingError(error.localizedDescription).description
            }
        }
    }

    func clearText() {
        speechText.originalText = ""
        speechText.processedText = ""
        lastSpokenLanguageCode = nil
    }

    func replaceText() {
        let temp = speechText.originalText
        speechText.originalText = speechText.processedText
        speechText.processedText = temp
        lastSpokenLanguageCode = nil
    }

    func copyProcessedText() {
        guard !speechText.processedText.isEmpty else {
            errorMessage = "No text to copy"
            return
        }

        UIPasteboard.general.string = speechText.processedText

        withAnimation { showCopySuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            withAnimation { self?.showCopySuccess = false }
        }
    }

    func speakProcessedText(languageCode: String? = nil) {
        Task { [weak self] in
            guard let self else { return }
            try? await self.speakProcessedTextInternal(languageCode: languageCode)
        }
    }

    private func speakProcessedTextInternal(languageCode: String? = nil) async throws {
        guard !speechText.processedText.isEmpty else {
            errorMessage = "No text to speak"
            return
        }

        let outputLanguageCode = languageCode ?? lastSpokenLanguageCode ?? selectedLanguage.code
        lastSpokenLanguageCode = outputLanguageCode

        audioPlayer?.stop()
        if let url = lastGeneratedSpeechURL {
            deleteFileIfPossible(url)
            lastGeneratedSpeechURL = nil
        }

        switch ttsOption {
        case .apple:
            do { try AudioSessionController.shared.configureForPlayback() } catch {}

            let utterance = AVSpeechUtterance(string: speechText.processedText)
            utterance.volume = 1.0
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
            if let voice = voiceForLanguage(code: outputLanguageCode) {
                utterance.voice = voice
            }
            speechSynthesizer.speak(utterance)

        case .openAI:
            processingMessage = "Generating speech…"
            isProcessing = true

            do { try AudioSessionController.shared.configureForPlayback() } catch {}

            do {
                let url = try await openAIService.generateSpeechAudio(
                    text: speechText.processedText,
                    voice: selectedVoice.rawValue
                )
                try Task.checkCancellation()

                lastGeneratedSpeechURL = url
                let player = try AVAudioPlayer(contentsOf: url)
                player.volume = 1.0
                player.delegate = self
                player.play()
                audioPlayer = player
            } catch is CancellationError {
                // silent
            } catch let err as AppError {
                errorMessage = err.description
            } catch {
                errorMessage = AppError.processingError("Failed to play audio: \(error.localizedDescription)").description
            }

            isProcessing = false
        }
    }

    // MARK: - Cancel

    func cancelProcessing() {
        currentTask?.cancel()
        currentTask = nil
        isProcessing = false
        processingMessage = "Processing..."
        isInterpreting = false
    }

    // MARK: - Corrections

    func addCorrection(incorrect: String, correct: String) {
        correctionManager.addCorrection(incorrect: incorrect, correct: correct)
    }

    func removeCorrection(for incorrect: String) {
        correctionManager.removeCorrection(for: incorrect)
    }

    func swapInterpreterLanguages() {
        let temp = interpreterLanguageA
        interpreterLanguageA = interpreterLanguageB
        interpreterLanguageB = temp
    }

    private func correctCommonMistranscriptions(text: String) -> String {
        var corrected = text
        for (incorrect, correct) in customCorrections {
            corrected = corrected.replacingOccurrences(of: incorrect, with: correct)
        }
        return corrected
    }

    // MARK: - Interpreter routing helpers

    private func normalizedLanguageCode(_ code: String) -> String {
        let lowercased = code.lowercased().replacingOccurrences(of: "_", with: "-")
        if let separator = lowercased.firstIndex(of: "-") {
            return String(lowercased[..<separator])
        }
        return lowercased
    }

    private func interpreterTargetLanguage(for detectedCode: String) -> Language {
        if language(interpreterLanguageA, matches: detectedCode) { return interpreterLanguageB }
        if language(interpreterLanguageB, matches: detectedCode) { return interpreterLanguageA }

        if language(selectedLanguage, matches: detectedCode) { return interpreterLanguageA }
        return interpreterLanguageB
    }

    private func language(_ language: Language, matches detectedCode: String) -> Bool {
        let normalized = normalizedLanguageCode(language.code)
        return normalized == detectedCode || language.code.lowercased() == detectedCode
    }

    private func voiceForLanguage(code: String) -> AVSpeechSynthesisVoice? {
        if let exact = AVSpeechSynthesisVoice(language: code) { return exact }
        let normalized = normalizedLanguageCode(code)
        return AVSpeechSynthesisVoice.speechVoices().first { voice in
            normalizedLanguageCode(voice.language) == normalized
        }
    }

    // MARK: - Processing runner

    private func runProcessing(message: String, operation: @escaping () async -> Void) {
        currentTask?.cancel()

        errorMessage = nil
        isProcessing = true
        processingMessage = message

        currentTask = Task { [weak self] in
            guard let self else { return }
            await operation()
            self.isProcessing = false
            self.processingMessage = "Processing..."
        }
    }

    // MARK: - File cleanup

    private func deleteFileIfPossible(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - AVAudioPlayerDelegate

    /// Make it nonisolated because the delegate callback is not guaranteed to be on MainActor.
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            if let url = self.lastGeneratedSpeechURL {
                self.deleteFileIfPossible(url)
                self.lastGeneratedSpeechURL = nil
            }
        }
    }
}
