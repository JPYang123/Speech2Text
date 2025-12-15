import SwiftUI

struct ManageCorrectionsView: View {
    @ObservedObject private var manager = CorrectionManager.shared
    @State private var incorrect = ""
    @State private var correct = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Add Correction")) {
                    TextField("Incorrect", text: $incorrect)
                    TextField("Correct", text: $correct)
                    Button("Add") {
                        manager.addCorrection(incorrect: incorrect, correct: correct)
                        incorrect = ""
                        correct = ""
                    }
                    .disabled(incorrect.isEmpty || correct.isEmpty)
                }

                Section(header: Text("Existing Corrections")) {
                    let keys = manager.corrections.keys.sorted()
                    ForEach(keys, id: \.self) { key in
                        HStack {
                            Text(key)
                            Spacer()
                            Text(manager.corrections[key] ?? "")
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
                
                if let message = manager.error?.description {
                    Text(message)
                        .foregroundColor(.red)
                }
            }
            .navigationBarTitle("Manage Corrections", displayMode: .inline)
        }
    }
}

struct ManageCorrectionsView_Previews: PreviewProvider {
    static var previews: some View {
        ManageCorrectionsView()
    }
}
