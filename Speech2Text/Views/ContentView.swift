import SwiftUI
import UIKit // for UIPasteboard in copy functionality

struct ContentView: View {
    @StateObject private var viewModel = SpeechViewModel()
    @State private var showCorrectionManager = false
    
    private let temperatureOptions: [Double] = (0...10).map { Double($0) / 10.0 }


    var body: some View {
        VStack(spacing: 16) {
            // Title
            Text("Voice Assistant")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)

            // Language picker + Temperature control
            HStack(spacing: 0) {
                // Language picker
                Picker("Language", selection: $viewModel.selectedLanguage) {
                    ForEach(viewModel.supportedLanguages, id: \.self) { lang in
                        Text(lang.name).tag(lang)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity)

                // Temperature picker as a compact menu showing current value
                Picker(selection: $viewModel.temperature) {
                    // MODIFY THIS ForEach:
                    ForEach(temperatureOptions, id: \.self) { value in
                        Text(String(format: "%.1f", value)).tag(value)
                    }
                } label: { // This part remains the same
                    Text(String(format: "%.1f", viewModel.temperature))
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            .frame(height: 44)

            // Waveform when recording
            if viewModel.isRecording {
                WaveformView(audioLevelMonitor: viewModel.audioService.audioLevelMonitor)
                    .transition(.opacity)
                    .animation(.easeInOut, value: viewModel.isRecording)
            }

            // Text boxes
            textBoxes

            // Primary Buttons: Record, Translate, Improve
            primaryButtonRow

            // Secondary Buttons: Clear, Replace, Copy
            secondaryButtonRow

            // Copy success message
            if viewModel.showCopySuccess {
                Text("Text copied to clipboard!")
                    .foregroundColor(.green)
                    .font(.footnote)
                    .padding(.top, 4)
                    .transition(.opacity)
            }

            // Error message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .padding()
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        // Dismiss keyboard on tap outside
        .onTapGesture {
            hideKeyboard()
        }
        // “Done” button above keyboard
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    hideKeyboard()
                }
            }
        }
        .sheet(isPresented: $showCorrectionManager) {
            ManageCorrectionsView()
        }
    }

    // MARK: – Subviews

    private var textBoxes: some View {
        VStack(spacing: 16) {
            // Original text
            VStack(alignment: .leading) {
                Text("Original Text")
                    .font(.headline)
                TextEditor(text: $viewModel.speechText.originalText)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1))
            }

            // Processed text
            VStack(alignment: .leading) {
                Text("Processed Text")
                    .font(.headline)
                TextEditor(text: $viewModel.speechText.processedText)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1))
            }
        }
    }

    private var primaryButtonRow: some View {
        HStack(spacing: 12) {
            // Record / Stop
            Button(action: viewModel.toggleRecording) {
                Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 40))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle(isDestructive: viewModel.isRecording))
            .disabled(viewModel.isProcessing)

            // Translate
            Button(action: viewModel.translateText) {
                Image(systemName: "globe")
                    .font(.system(size: 40))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.isProcessing || viewModel.speechText.originalText.isEmpty)

            // Improve
            Button(action: viewModel.improveText) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 40))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.isProcessing || viewModel.speechText.originalText.isEmpty)
        }
        .overlay(
            Group {
                if viewModel.isProcessing {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("Processing...")
                    }
                    .padding(8)
                    .background(Color(.systemBackground).opacity(0.8))
                    .cornerRadius(8)
                }
            }
        )
    }

    private var secondaryButtonRow: some View {
        HStack(spacing: 12) {
            // Clear
            Button(action: viewModel.clearText) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 40))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle(isDestructive: true))
            .disabled(viewModel.isProcessing)

            // Replace
            Button(action: viewModel.replaceText) {
                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .font(.system(size: 40))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.isProcessing || viewModel.speechText.processedText.isEmpty)

            // Copy
            Button(action: viewModel.copyProcessedText) {
                Image(systemName: "doc.on.doc.fill")
                    .font(.system(size: 40))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.isProcessing || viewModel.speechText.processedText.isEmpty)
            
            // Manage Corrections
            Button(action: { showCorrectionManager = true }) {
                Image(systemName: "text.book.closed")
                    .font(.system(size: 40))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.isProcessing)
        }
    }
}

// Custom button style
struct PrimaryButtonStyle: ButtonStyle {
    var isDestructive: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 12)
            .background(isDestructive ? Color.red : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
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
