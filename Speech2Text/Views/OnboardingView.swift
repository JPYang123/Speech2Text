import SwiftUI

struct OnboardingStep {
    let title: String
    let message: String
    let icon: String
}

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentStep = 0
    @Environment(\.dismiss) private var dismiss

    private let steps: [OnboardingStep] = [
        OnboardingStep(
            title: "Welcome",
            message: "Speech2Text lets you record speech and transcribe it with OpenAI.",
            icon: "waveform"
        ),
        OnboardingStep(
            title: "OpenAI API Key",
            message: "Create an API key at platform.openai.com and enter it under Settings > Set OpenAI API Key.",
            icon: "key.fill"
        ),
        OnboardingStep(
            title: "Record",
            message: "Tap the Record button to start capturing audio.",
            icon: "mic.circle.fill"
        ),
        OnboardingStep(
            title: "Translate or Improve",
            message: "After transcribing, use the Translate or Improve buttons to process the text.",
            icon: "wand.and.stars"
        ),
        OnboardingStep(
            title: "Speak Text",
            message: "Tap the Speak button to listen to the processed text with text to speech.",
            icon: "speaker.wave.2.fill"
        ),
        OnboardingStep(
            title: "Copy Results",
            message: "Use the Copy button to put the processed text on the clipboard.",
            icon: "doc.on.doc.fill"
        ),
        OnboardingStep(
            title: "Manage Corrections",
            message: "Add custom word fixes or replay this guide anytime from Settings.",
            icon: "text.book.closed"
        )
    ]

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: steps[currentStep].icon)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.accentColor)
                .transition(.scale)

            Text(steps[currentStep].title)
                .font(.title)
                .fontWeight(.bold)
                .transition(.opacity)

            Text(steps[currentStep].message)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .transition(.opacity)
            Spacer()

            Button(action: nextStep) {
                Text(currentStep == steps.count - 1 ? "Get Started" : "Next")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
        }
        .padding()
        .animation(.easeInOut, value: currentStep)
    }

    private func nextStep() {
        withAnimation {
            if currentStep < steps.count - 1 {
                currentStep += 1
            } else {
                hasSeenOnboarding = true
                dismiss()
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
