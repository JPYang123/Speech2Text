import SwiftUI
import UIKit // for UIPasteboard in copy functionality

struct ContentView: View {
    @StateObject private var viewModel = SpeechViewModel()
    @State private var showSettings = false
    
    private let temperatureOptions: [Double] = (0...10).map { Double($0) / 10.0 }

    var body: some View {
        VStack(spacing: 16) {
            // Title
            Text("Voice Assistant")
                .font(.system(size: 48, weight: .bold))
                .fontWeight(.bold)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding(.top)

            // Language picker
            HStack(spacing: 12) {
                Picker("Language", selection: $viewModel.selectedLanguage) {
                    ForEach(viewModel.supportedLanguages, id: \.self) { lang in
                        Text(lang.name).tag(lang)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)

            // Waveform when recording (properly sized section)
            if viewModel.isRecording {
                WaveformView(audioLevelMonitor: viewModel.audioService.audioLevelMonitor)
                    .frame(height: 140) // Reduced height for better proportions
                    .padding(.horizontal)
                    .padding(.vertical, 4) // Reduced vertical padding
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6).opacity(0.2))
                    )
                    .transition(.scale.combined(with: .opacity))
                    .animation(.easeInOut, value: viewModel.isRecording)
            }

            // Text boxes
            textBoxes

            // Primary Buttons: Record, Translate, Improve
            primaryButtonRow

            // Secondary Buttons: Clear, Replace, Copy, Manage
            secondaryButtonRow

            // Copy success message
            if viewModel.showCopySuccess {
                Text("Text copied to clipboard!")
                    .foregroundColor(.green)
                    .font(.footnote)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.1))
                            .overlay(
                                Capsule()
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .transition(.scale.combined(with: .opacity))
            }

            // Error message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        // Dismiss keyboard on tap outside
        .onTapGesture {
            hideKeyboard()
        }
        // "Done" button above keyboard
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    hideKeyboard()
                }
                .font(.body.weight(.semibold))
                .foregroundColor(.blue)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel)
        }
    }

    // MARK: – Subviews

    private var textBoxes: some View {
        VStack(spacing: 16) {
            // Original text
            VStack(alignment: .leading) {
                Text("Original Text")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                TextEditor(text: $viewModel.speechText.originalText)
                    .frame(minHeight: 120)
                    .padding(12)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                viewModel.speechText.originalText.isEmpty ?
                                Color(.systemGray4) : Color.blue.opacity(0.5),
                                lineWidth: viewModel.speechText.originalText.isEmpty ? 1 : 1.5
                            )
                    )
                    .shadow(color: .black.opacity(0.02), radius: 2, x: 0, y: 1)
            }

            // Processed text
            VStack(alignment: .leading) {
                Text("Processed Text")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                TextEditor(text: $viewModel.speechText.processedText)
                    .frame(minHeight: 120)
                    .padding(12)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                viewModel.speechText.processedText.isEmpty ?
                                Color(.systemGray4) : Color.green.opacity(0.5),
                                lineWidth: viewModel.speechText.processedText.isEmpty ? 1 : 1.5
                            )
                    )
                    .shadow(color: .black.opacity(0.02), radius: 2, x: 0, y: 1)
            }
        }
    }

    private var primaryButtonRow: some View {
        HStack(spacing: 14) {
            // Record / Stop
            Button(action: viewModel.toggleRecording) {
                VStack(spacing: 4) { // Reduced spacing from 6 to 4
                    Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 24)) // Reduced from 28 to 24
                    Text(viewModel.isRecording ? "Stop" : "Record")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .buttonStyle(ModernButtonStyle(
                color: viewModel.isRecording ? .red : .blue,
                isDisabled: viewModel.isProcessing
            ))
            .disabled(viewModel.isProcessing)

            // Translate
            Button(action: viewModel.translateText) {
                VStack(spacing: 4) { // Reduced spacing from 6 to 4
                    Image(systemName: "globe")
                        .font(.system(size: 24)) // Reduced from 28 to 24
                    Text("Translate")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .buttonStyle(ModernButtonStyle(
                color: .orange,
                isDisabled: viewModel.isProcessing || viewModel.speechText.originalText.isEmpty
            ))
            .disabled(viewModel.isProcessing || viewModel.speechText.originalText.isEmpty)

            // Improve
            Button(action: viewModel.improveText) {
                VStack(spacing: 4) { // Reduced spacing from 6 to 4
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 24)) // Reduced from 28 to 24
                    Text("Improve")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .buttonStyle(ModernButtonStyle(
                color: .purple,
                isDisabled: viewModel.isProcessing || viewModel.speechText.originalText.isEmpty
            ))
            .disabled(viewModel.isProcessing || viewModel.speechText.originalText.isEmpty)
        }
        .overlay(
            Group {
                if viewModel.isProcessing {
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(0.9)
                        Text("Processing...")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                }
            }
        )
        .frame(maxWidth: .infinity)
    }

    private var secondaryButtonRow: some View {
        HStack(spacing: 14) {
            // Clear
            Button(action: viewModel.clearText) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 26))
            }
            .buttonStyle(SecondaryButtonStyle(
                color: .red,
                isDisabled: viewModel.isProcessing
            ))
            .disabled(viewModel.isProcessing)

            // Replace
            Button(action: viewModel.replaceText) {
                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .font(.system(size: 26))
            }
            .buttonStyle(SecondaryButtonStyle(
                color: .indigo,
                isDisabled: viewModel.isProcessing || viewModel.speechText.processedText.isEmpty
            ))
            .disabled(viewModel.isProcessing || viewModel.speechText.processedText.isEmpty)

            // Copy
            Button(action: viewModel.copyProcessedText) {
                Image(systemName: "doc.on.doc.fill")
                    .font(.system(size: 26))
            }
            .buttonStyle(SecondaryButtonStyle(
                color: .green,
                isDisabled: viewModel.isProcessing || viewModel.speechText.processedText.isEmpty
            ))
            .disabled(viewModel.isProcessing || viewModel.speechText.processedText.isEmpty)
            
            // Settings
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 26))
            }
            .buttonStyle(SecondaryButtonStyle(
                color: .gray,
                isDisabled: viewModel.isProcessing
            ))
            .disabled(viewModel.isProcessing)
        }
        .frame(maxWidth: .infinity)
    }
}

// Modern button style for primary buttons (3-button row with labels)
struct ModernButtonStyle: ButtonStyle {
    let color: Color
    var isDisabled: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10) // Reduced from 14 to 10
            .foregroundColor(.white)
            .background(
                LinearGradient(
                    colors: isDisabled ?
                        [Color(.systemGray4), Color(.systemGray5)] :
                        [color, color.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(12) // Reduced from 14 to 12
            .shadow(
                color: isDisabled ? .clear : color.opacity(0.25),
                radius: 4, // Reduced from 6 to 4
                x: 0,
                y: 2 // Reduced from 3 to 2
            )
            .scaleEffect(configuration.isPressed ? 0.96 : (isDisabled ? 0.95 : 1.0))
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.2), value: isDisabled)
    }
}

// Secondary button style for 4-button row (larger circular buttons)
struct SecondaryButtonStyle: ButtonStyle {
    let color: Color
    var isDisabled: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .frame(width: 70, height: 70) // Increased from 60x60 to better match primary buttons
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isDisabled ?
                                [Color(.systemGray4), Color(.systemGray5)] :
                                [color, color.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(
                        color: isDisabled ? .clear : color.opacity(0.25),
                        radius: 6,
                        x: 0,
                        y: 3
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.92 : (isDisabled ? 0.9 : 1.0))
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.2), value: isDisabled)
    }
}

// Helper extension for multipart form data
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        }
    }
}

// MARK: - View Extension for Keyboard Dismissal
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                       to: nil, from: nil, for: nil)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
