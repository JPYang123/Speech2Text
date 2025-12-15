import Foundation
import AVFoundation

@MainActor
final class AudioService: NSObject, ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var audioFileURL: URL?

    @Published private(set) var isRecording = false
    @Published var error: AppError?

    let audioLevelMonitor = AudioLevelMonitor()

    func startRecording() {
        error = nil
        guard !isRecording else { return }

        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] allowed in
                Task { @MainActor in
                    guard let self else { return }
                    if allowed {
                        self.startRecordingAfterPermission()
                    } else {
                        self.error = .recordingError("Microphone access denied")
                    }
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] allowed in
                Task { @MainActor in
                    guard let self else { return }
                    if allowed {
                        self.startRecordingAfterPermission()
                    } else {
                        self.error = .recordingError("Microphone access denied")
                    }
                }
            }
        }
    }

    private func startRecordingAfterPermission() {
        do {
            try AudioSessionController.shared.configureForRecording()
            try initiateRecording()
            isRecording = true
        } catch {
            self.error = .recordingError("Failed to start recording: \(error.localizedDescription)")
        }
    }

    private func initiateRecording() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("recording_\(Int(Date().timeIntervalSince1970)).m4a")
        audioFileURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.isMeteringEnabled = true
        recorder.prepareToRecord()
        recorder.record()

        audioRecorder = recorder
        audioLevelMonitor.startMonitoring(audioRecorder: recorder)
    }

    /// Stops recording and returns the audio file URL.
    /// Caller can delete the file after it’s consumed (recommended).
    func stopRecording() -> URL? {
        guard isRecording else { return nil }

        audioRecorder?.stop()
        audioLevelMonitor.stopMonitoring()

        isRecording = false

        let url = audioFileURL
        audioRecorder = nil
        audioFileURL = nil

        do {
            try AudioSessionController.shared.deactivate()
        } catch {
            // Not fatal; ignore.
        }

        return url
    }
}
