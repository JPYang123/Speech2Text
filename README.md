# Speech2Text

Speech2Text is an iOS voice assistant built with SwiftUI. It records spoken audio, transcribes it with OpenAI models and optionally translates or improves the resulting text. The app includes a simple waveform display while recording and lets users manage custom word corrections.

## Features

- **Audio Recording** – Uses `AVFoundation` to capture audio and visualize the microphone level during recording. See `AudioService.swift` lines 4‑78 for implementation details.
- **OpenAI Integration** – Transcribes speech and performs chat completions using your OpenAI API key. The service is defined in `OpenAIService.swift` lines 1‑198.
- **Text Translation & Improvement** – Translate the transcription into different languages or improve the wording using GPT models (`SpeechViewModel.swift` lines 92‑151).
- **Custom Corrections** – Maintain a list of user‑defined correction pairs stored in JSON. Managed in `CorrectionManager.swift`.
- **Clipboard Copy** – The Copy button places the processed text on the clipboard for easy sharing.
- **Text to Speech** – Listen to results with the built-in **Speak** option using either Apple's system voices or OpenAI's TTS API.
- **Temperature Control** – Adjust the OpenAI response creativity from the Settings screen.
- **UI** – A SwiftUI interface with text boxes, waveform visualization and buttons for recording, translating, improving, speaking and managing corrections (`ContentView.swift`).
- **Onboarding** – A short animated guide explains the main actions. It shows automatically on first launch and can be replayed from **Settings > Quick Guide** (`OnboardingView.swift`).

## Project Structure

```
Speech2Text/
├── Speech2TextApp.swift        # App entry point
├── Models/                     # Data models and configuration
│   ├── Models.swift            # API keys & model names
│   ├── AudioLevelMonitor.swift # Recording level visualization
│   └── ...
├── Services/                   # Audio and OpenAI services
├── ViewModel/                  # SpeechViewModel logic
└── Views/                      # SwiftUI views
```

## Requirements

- Xcode with iOS 17 SDK
- An OpenAI API key

## Setup

1. Clone the repository and open `Speech2Text.xcodeproj` in Xcode.
2. Obtain an API key from <https://platform.openai.com/account/api-keys>. After signing in you can create a new secret key. Set it as the environment variable `OPENAI_API_KEY` in your run scheme or enter it from **Settings > API Key** inside the app (it is stored in `UserDefaults`). **Do not commit real keys to source control.**
3. Build and run on a device or simulator.

## Usage

Upon first launch the app presents an animated walkthrough of these steps (you can replay it anytime from **Settings > Quick Guide**):
1. Tap **Record** to start capturing audio. A waveform and timer display the current recording.
2. Tap **Stop** to transcribe. The transcription appears in the *Original Text* field.
3. Use **Translate** or **Improve** to process the text. Results appear in the *Processed Text* field.
4. Tap **Speak** to hear the processed text using the selected TTS engine.
5. Tap **Copy** to place the processed text on the clipboard.
6. Use **Settings** to manage custom corrections, choose the TTS engine, adjust the response temperature, or set your API key.

## Notes

- The project includes Word documents containing earlier revisions of the source code.
- API keys should be handled securely in a production app; storing them in plain text as shown here is for development only.

