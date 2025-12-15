//
//  InterpreterTab.swift
//  Speech2Text
//
//  Created by Jiping Yang on 11/26/25.
//

import SwiftUI
import UIKit

// MARK: - Interpreter Tab
struct InterpreterTab: View {
    @ObservedObject var viewModel: SpeechViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Language Selection - Original Horizontal Design
                    VStack(spacing: 12) {
                        Text("Interpreter languages")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.primary.opacity(0.7))
                        
                        HStack(spacing: 12) {
                            Spacer(minLength: 0)
                            
                            Picker("Interpreter Language A", selection: $viewModel.interpreterLanguageA) {
                                ForEach(viewModel.supportedLanguages, id: \.self) { lang in
                                    Text(lang.name).tag(lang)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .frame(maxWidth: 180)
                            
                            Button(action: viewModel.swapInterpreterLanguages) {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: 18, weight: .semibold))
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                            }
                            .accessibilityLabel("Swap interpreter languages")
                            
                            Picker("Interpreter Language B", selection: $viewModel.interpreterLanguageB) {
                                ForEach(viewModel.supportedLanguages, id: \.self) { lang in
                                    Text(lang.name).tag(lang)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .frame(maxWidth: 180)
                            
                            Spacer(minLength: 0)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 10)
                    )
                    
                    // Recording Section
                    VStack(spacing: 16) {
                        if viewModel.isRecording && viewModel.isInterpreting {
                            WaveformView(audioLevelMonitor: viewModel.audioService.audioLevelMonitor)
                                .frame(height: 140)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemGray6))
                                )
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Image(systemName: "ear.badge.waveform")
                                .font(.system(size: 80))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.teal, .cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .padding(.vertical)
                        }
                        
                        Button(action: viewModel.toggleInterpreter) {
                            HStack {
                                Image(systemName: viewModel.isRecording && viewModel.isInterpreting ? "stop.circle.fill" : "play.circle.fill")
                                    .font(.title2)
                                Text(viewModel.isRecording && viewModel.isInterpreting ? "Stop Interpreter" : "Start Interpreter")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.isRecording && viewModel.isInterpreting ? Color.red : Color.teal)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                        .disabled(viewModel.isProcessing)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 10)
                    )
                    
                    // Conversation Display
                    if !viewModel.speechText.originalText.isEmpty || !viewModel.speechText.processedText.isEmpty {
                        VStack(spacing: 16) {
                            if !viewModel.speechText.originalText.isEmpty {
                                ConversationBubble(
                                    text: viewModel.speechText.originalText,
                                    isLeft: true
                                )
                            }
                            
                            if !viewModel.speechText.processedText.isEmpty {
                                ConversationBubble(
                                    text: viewModel.speechText.processedText,
                                    isLeft: false
                                )
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 10)
                        )
                    }
                    
                    // Error/Success Messages
                    if let errorMessage = viewModel.errorMessage {
                        ErrorBanner(message: errorMessage)
                    }
                }
                .padding()
            }
            .navigationTitle("Interpreter")
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

struct InterpreterTab_Previews: PreviewProvider {
    static var previews: some View {
        InterpreterTab(viewModel: SpeechViewModel())
    }
}
