import SwiftUI

/// Simple view for entering and storing the OpenAI API key.
struct APIKeyView: View {
    @State private var apiKey: String = UserDefaults.standard.string(forKey: "OpenAIAPIKey") ?? ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("OpenAI API Key")) {
                    Text("Create a key at platform.openai.com and paste it below.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    SecureField("sk-...", text: $apiKey)
                    Button("Save") {
                        UserDefaults.standard.set(apiKey, forKey: "OpenAIAPIKey")
                        dismiss()
                    }
                    .disabled(apiKey.isEmpty)
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
}

struct APIKeyView_Previews: PreviewProvider {
    static var previews: some View {
        APIKeyView()
    }
}
