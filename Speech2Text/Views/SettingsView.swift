import SwiftUI

/// Consolidated settings screen providing access to correction manager,
/// API key entry and onboarding replay.
struct SettingsView: View {
    @ObservedObject var viewModel: SpeechViewModel
    @State private var showCorrections = false
    @State private var showAPIKey = false
    @State private var showOnboarding = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Button("Manage Corrections") { showCorrections = true }
                    Button("Set OpenAI API Key") { showAPIKey = true }
                    Button("View Quick Guide") { showOnboarding = true }
                }

                Section(header: Text("Response Temperature")) {
                    HStack {
                        Slider(value: $viewModel.temperature, in: 0...1, step: 0.1)
                        Text(String(format: "%.1f", viewModel.temperature))
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 44)
                    }
                }
                
                Section(header: Text("Text to Speech")) {
                    Picker("Engine", selection: $viewModel.ttsOption) {
                        ForEach(TTSOption.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showCorrections) {
                ManageCorrectionsView()
            }
            .sheet(isPresented: $showAPIKey) {
                APIKeyView()
            }
            .sheet(isPresented: $showOnboarding) {
                OnboardingView()
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: SpeechViewModel())
    }
}
