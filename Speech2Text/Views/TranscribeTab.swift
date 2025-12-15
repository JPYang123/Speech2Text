//
//  TranscribeTab.swift
//  Speech2Text
//
//  Created by Jiping Yang on 11/26/25.
//

import SwiftUI
import UIKit

// MARK: - Transcribe Tab
struct TranscribeTab: View {
    @ObservedObject var viewModel: SpeechViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Waveform/Icon Section
                    VStack(spacing: 16) {
                        if viewModel.isRecording {
                            WaveformView(audioLevelMonitor: viewModel.audioService.audioLevelMonitor)
                                .frame(height: 140)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemGray6))
                                )
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .padding(.top)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 10)
                    )
                    
                    // Transcribed Text Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Transcribed Text")
                                .font(.headline)
                            Spacer()
                            
                            // Only show actions if there is text
                            if !viewModel.speechText.originalText.isEmpty {
                                // NEW: Delete/Clear Button
                                Button(action: {
                                    withAnimation {
                                        viewModel.speechText.originalText = ""
                                    }
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .padding(.trailing, 8) // Add some spacing between Trash and Copy
                                
                                // Existing Copy Button
                                Button(action: {
                                    UIPasteboard.general.string = viewModel.speechText.originalText
                                    viewModel.showCopySuccess = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        viewModel.showCopySuccess = false
                                    }
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        TextEditor(text: $viewModel.speechText.originalText)
                            .frame(minHeight: 200)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            // NEW: Keyboard Dismissal Toolbar
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Done") {
                                        hideKeyboard() // Uses extension from Source: 159
                                    }
                                }
                            }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 10)
                    )
                    
                    // Record Button (moved below text box)
                    Button(action: viewModel.toggleRecording) {
                        HStack {
                            Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.title2)
                            Text(viewModel.isRecording ? "Stop Recording" : "Start Recording")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isRecording ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .disabled(viewModel.isProcessing)
                    .padding(.horizontal)
                    
                    // Error/Success Messages
                    if let errorMessage = viewModel.errorMessage {
                        ErrorBanner(message: errorMessage)
                    }
                    
                    if viewModel.showCopySuccess {
                        SuccessBanner(message: "Copied to clipboard!")
                    }
                }
                .padding()
            }
            .navigationTitle("Transcribe")
            .overlay(
                Group {
                    if viewModel.isProcessing {
                        ProcessingOverlay()
                    }
                }
            )
        }
    }
}

struct TranscribeTab_Previews: PreviewProvider {
    static var previews: some View {
        TranscribeTab(viewModel: SpeechViewModel())
    }
}
