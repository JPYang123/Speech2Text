import SwiftUI

struct APIKeyView: View {
    @State private var apiKey: String = KeychainStore.loadString(forKey: APIConfig.openAIKeyIdentifier) ?? ""
    @State private var errorText: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("OpenAI API Key")) {
                    Text("Create a key at platform.openai.com and paste it below.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    SecureField("sk-...", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    HStack {
                        Button("Save") {
                            do {
                                try APIConfig.saveOpenAIKey(apiKey)
                                dismiss()
                            } catch {
                                errorText = "Failed to save key."
                            }
                        }
                        .disabled(!looksLikeOpenAIKey(apiKey))

                        Button("Clear") {
                            APIConfig.clearOpenAIKey()
                            apiKey = ""
                        }
                        .foregroundStyle(.red)
                        .disabled(apiKey.isEmpty && !APIConfig.hasKey)
                    }

                    if let errorText {
                        Text(errorText)
                            .foregroundStyle(.red)
                    }

                    if APIConfig.hasKey {
                        Text("Status: ✅ Key is set")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    } else {
                        Text("Status: ❌ Key not set")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    /// Heuristic only (OpenAI key formats may evolve).
    private func looksLikeOpenAIKey(_ key: String) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("sk-") && trimmed.count >= 20
    }
}

struct APIKeyView_Previews: PreviewProvider {
    static var previews: some View { APIKeyView() }
}
