//
//  SettingsTab.swift
//  Speech2Text
//
//  Created by Jiping Yang on 11/26/25.
//

import SwiftUI
import UIKit

// MARK: - Settings Tab
struct SettingsTab: View {
    @ObservedObject var viewModel: SpeechViewModel
    @State private var showCorrections = false
    @State private var showAPIKey = false
    @State private var showOnboarding = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Quick Access")) {
                    NavigationLink(destination: ManageCorrectionsView()) {
                        Label("Manage Corrections", systemImage: "text.book.closed")
                    }
                    
                    Button(action: { showAPIKey = true }) {
                        Label("Set OpenAI API Key", systemImage: "key.fill")
                    }
                    
                    Button(action: { showOnboarding = true }) {
                        Label("View Quick Guide", systemImage: "questionmark.circle")
                    }
                }
                
                Section(header: Text("AI Settings")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Temperature")
                            Spacer()
                            Text(String(format: "%.1f", viewModel.temperature))
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $viewModel.temperature, in: 0...1, step: 0.1)
                    }
                }
                
                Section(header: Text("Text to Speech")) {
                    Picker("Engine", selection: $viewModel.ttsOption) {
                        ForEach(TTSOption.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if viewModel.ttsOption == .openAI {
                        Picker("Voice", selection: $viewModel.selectedVoice) {
                            ForEach(OpenAIVoice.allCases) { voice in
                                Text(voice.displayName).tag(voice)
                            }
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showAPIKey) {
                APIKeyView()
            }
            .sheet(isPresented: $showOnboarding) {
                OnboardingView()
            }
        }
    }
}

