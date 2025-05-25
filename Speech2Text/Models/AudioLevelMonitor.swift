
import Foundation
import AVFoundation

class AudioLevelMonitor: ObservableObject {
    @Published var soundSamples: [CGFloat] = Array(repeating: 0, count: WaveformConfig.numberOfSamples)
    @Published var recordingDuration: TimeInterval = 0
    
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var startTime: Date?
    
    func startMonitoring(audioRecorder: AVAudioRecorder) {
        self.audioRecorder = audioRecorder
        self.audioRecorder?.isMeteringEnabled = true
        self.soundSamples = Array(repeating: 0, count: WaveformConfig.numberOfSamples)
        self.recordingDuration = 0
        
        startTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: WaveformConfig.updateInterval, repeats: true) { [weak self] _ in
            self?.updateMeters()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        startTime = nil
        recordingDuration = 0
    }
    
    private func updateMeters() {
        guard let audioRecorder = audioRecorder else { return }
        
        audioRecorder.updateMeters()
        
        // Update recording duration
        if let startTime = startTime {
            recordingDuration = Date().timeIntervalSince(startTime)
        }
        
        // Shift samples and add the new value
        soundSamples.removeFirst()
        
        // Get the power in decibels
        let decibels = audioRecorder.averagePower(forChannel: 0)
        
        // Convert decibels to linear scale (0.0 to 1.0)
        // Audio levels in decibels are typically negative, with 0dB being the maximum
        // and -160dB being the minimum. We normalize this to 0.0-1.0 range.
        var level: CGFloat = 0
        if decibels > -50 { // Only show values above a certain threshold
            // Convert from decibels (-160...0) to linear (0...1) with some normalization
            level = CGFloat(pow(10, Float(decibels) / 20))
            
            // Apply some scaling for better visualization
            level = min(max(level, CGFloat(WaveformConfig.minAmplitude)), CGFloat(WaveformConfig.maxAmplitude))
        }
        
        soundSamples.append(level)
    }
}
