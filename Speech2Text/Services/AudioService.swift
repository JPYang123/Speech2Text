import Foundation
import AVFoundation

// Service for handling audio recording
class AudioService: NSObject, ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var recordingSession: AVAudioSession?
    private var audioFilePath: URL?
    
    @Published var isRecording = false
    @Published var error: AppError?
    
    // Add audio level monitor for visualization
    let audioLevelMonitor = AudioLevelMonitor()
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession?.setCategory(.playAndRecord, mode: .default)
            try recordingSession?.setActive(true)
        } catch {
            self.error = .recordingError("Failed to set up recording session: \(error.localizedDescription)")
        }
    }
    
    func startRecording() {
        // Check permissions
        recordingSession?.requestRecordPermission { [weak self] allowed in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if allowed {
                    self.initiateRecording()
                } else {
                    self.error = .recordingError("Microphone access denied")
                }
            }
        }
    }
    
    private func initiateRecording() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        audioFilePath = documentsDirectory.appendingPathComponent("recording.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilePath!, settings: settings)
            audioRecorder?.record()
            isRecording = true
            
            // Start monitoring audio levels for visualization
            audioLevelMonitor.startMonitoring(audioRecorder: audioRecorder!)
            
        } catch let recordingError {
            self.error = .recordingError("Could not start recording: \(recordingError.localizedDescription)")
        }
    }
    
    func stopRecording() -> URL? {
        audioRecorder?.stop()
        isRecording = false
        
        // Stop monitoring audio levels
        audioLevelMonitor.stopMonitoring()
        
        return audioFilePath
    }
}
