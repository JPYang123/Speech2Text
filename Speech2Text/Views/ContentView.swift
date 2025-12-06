import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var viewModel = SpeechViewModel()
    
    var body: some View {
        TabView {
            TranscribeTab(viewModel: viewModel)
                .tabItem {
                    Label("Transcribe", systemImage: "mic.circle.fill")
                }
            
            TranslateTab(viewModel: viewModel)
                .tabItem {
                    Label("Translate", systemImage: "globe")
                }
            
            InterpreterTab(viewModel: viewModel)
                .tabItem {
                    Label("Interpreter", systemImage: "ear.badge.waveform")
                }
            
            SettingsTab(viewModel: viewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .accentColor(.blue)
    }
}

// MARK: - Helper Extensions
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                       to: nil, from: nil, for: nil)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
