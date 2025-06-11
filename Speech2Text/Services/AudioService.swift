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
        setupInitialAudioSession()
    }
    
    private func setupInitialAudioSession() {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            // Set a more flexible category initially
            try recordingSession?.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try recordingSession?.setActive(false) // Don't activate until needed
        } catch {
            self.error = .recordingError("Failed to set up recording session: \(error.localizedDescription)")
        }
    }
    
    func startRecording() {
        // Check permissions using the new iOS 17+ API
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] allowed in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if allowed {
                        self.configureAudioSessionForRecording()
                        self.initiateRecording()
                    } else {
                        self.error = .recordingError("Microphone access denied")
                    }
                }
            }
        } else {
            // Fallback for iOS versions before 17.0
            recordingSession?.requestRecordPermission { [weak self] allowed in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if allowed {
                        self.configureAudioSessionForRecording()
                        self.initiateRecording()
                    } else {
                        self.error = .recordingError("Microphone access denied")
                    }
                }
            }
        }
    }
    
    private func configureAudioSessionForRecording() {
        do {
            // Configure specifically for recording
            try recordingSession?.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
            try recordingSession?.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.error = .recordingError("Failed to configure audio session for recording: \(error.localizedDescription)")
        }
    }
    
    private func initiateRecording() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        audioFilePath = documentsDirectory.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilePath!, settings: settings)
            audioRecorder?.isMeteringEnabled = true // Enable for level monitoring
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
        
        // Reset audio session to allow other audio operations
        resetAudioSession()
        
        return audioFilePath
    }
    
    private func resetAudioSession() {
        do {
            // Reset to a more flexible category after recording
            try recordingSession?.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            // Don't deactivate the session completely, just reset the category
        } catch {
            print("Failed to reset audio session: \(error.localizedDescription)")
        }
    }
    
    deinit {
        // Clean up audio session when service is deallocated
        do {
            try recordingSession?.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }
}
