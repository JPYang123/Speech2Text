import Foundation
import AVFoundation
import SwiftUI

@MainActor
final class AudioLevelMonitor: ObservableObject {
    /// Internal ring buffer storage (fixed size).
    @Published private var buffer: [CGFloat] = Array(repeating: 0, count: WaveformConfig.numberOfSamples)

    @Published var recordingDuration: TimeInterval = 0

    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var startTime: Date?
    private var writeIndex: Int = 0

    /// Samples ordered from oldest -> newest (for display).
    var soundSamples: [CGFloat] {
        guard !buffer.isEmpty else { return [] }
        if writeIndex == 0 { return buffer }
        return Array(buffer[writeIndex...] + buffer[..<writeIndex])
    }

    func startMonitoring(audioRecorder: AVAudioRecorder) {
        self.audioRecorder = audioRecorder
        self.audioRecorder?.isMeteringEnabled = true

        buffer = Array(repeating: 0, count: WaveformConfig.numberOfSamples)
        recordingDuration = 0
        writeIndex = 0
        startTime = Date()

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: WaveformConfig.updateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMeters()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        audioRecorder = nil
        startTime = nil
        recordingDuration = 0
        writeIndex = 0
        buffer = Array(repeating: 0, count: WaveformConfig.numberOfSamples)
    }

    private func updateMeters() {
        guard let audioRecorder else { return }

        audioRecorder.updateMeters()

        if let startTime {
            recordingDuration = Date().timeIntervalSince(startTime)
        }

        let decibels = audioRecorder.averagePower(forChannel: 0)

        // Convert decibels to linear scale (0...1).
        var level: CGFloat = 0
        if decibels > -50 {
            level = CGFloat(pow(10, Float(decibels) / 20))
            level = min(max(level, CGFloat(WaveformConfig.minAmplitude)), CGFloat(WaveformConfig.maxAmplitude))
        }

        // Write to ring buffer.
        if buffer.isEmpty { return }
        buffer[writeIndex] = level
        writeIndex = (writeIndex + 1) % buffer.count
    }
}
