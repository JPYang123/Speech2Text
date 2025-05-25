import SwiftUI
import Foundation

// Waveform Configuration
struct WaveformConfig {
    static let numberOfSamples = 30 // Number of bars in the visualization
    static let updateInterval: TimeInterval = 0.05 // Update every 50ms
    static let minAmplitude: Float = 0.05 // Minimum amplitude to show
    static let maxAmplitude: Float = 1.0 // Max amplitude
    static let waveColor = Color.red // Color of the waveform
}
