import SwiftUI

struct WaveformView: View {
    @ObservedObject var audioLevelMonitor: AudioLevelMonitor
    
    var body: some View {
        VStack {
            // Timer display
            Text(timeString(from: audioLevelMonitor.recordingDuration))
                .font(.system(size: 40, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.bottom)
            
            // Waveform visualization
            HStack(spacing: 4) {
                ForEach(0..<audioLevelMonitor.soundSamples.count, id: \.self) { index in
                    BarView(value: audioLevelMonitor.soundSamples[index])
                }
            }
            .frame(height: 100)
            .padding()
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        let hundredths = Int((timeInterval.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, hundredths)
    }
}

struct BarView: View {
    var value: CGFloat
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(WaveformConfig.waveColor)
                .frame(width: 3, height: max(value * 100, 3))
        }
    }
}
