import SwiftUI

struct ManageCorrectionsView: View {
    @ObservedObject private var manager = CorrectionManager.shared
    @State private var incorrect: String = ""
    @State private var correct: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Add Correction")) {
                    TextField("Incorrect", text: $incorrect)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("Correct", text: $correct)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Button("Add") {
                        let from = incorrect.trimmingCharacters(in: .whitespacesAndNewlines)
                        let to = correct.trimmingCharacters(in: .whitespacesAndNewlines)
                        manager.addCorrection(incorrect: from, correct: to)
                        incorrect = ""
                        correct = ""
                    }
                    .disabled(incorrect.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              correct.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Section(header: Text("Existing Corrections")) {
                    let keys = manager.corrections.keys.sorted()
                    if keys.isEmpty {
                        Text("No corrections yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(keys, id: \.self) { key in
                            HStack {
                                Text(key)
                                Spacer()
                                Text(manager.corrections[key] ?? "")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete { indexSet in
                            let keys = manager.corrections.keys.sorted()
                            for index in indexSet {
                                let key = keys[index]
                                manager.removeCorrection(for: key)
                            }
                        }
                    }
                }

                if let message = manager.error?.description {
                    Text(message)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Manage Corrections")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ManageCorrectionsView_Previews: PreviewProvider {
    static var previews: some View { ManageCorrectionsView() }
}
