# TextToSpeech
This is a Challenge Project to assess the developer technical skills. 
Used integrations:
- Native Audio Transcription to get the message for user interaction based on user Speech.
- Native Speech Synthesizer to read LLM responses aloud.
- LLM Completion responses are mocked for lack of (paid) ChatGPT API key for testing purposes.

## Libraries used
### Alamofire
Used to perform HTTP requests.

## Design pattern
### Architecture
The project was built over MVVM architecture, using Combine to assure UI and Business layers consistency.
### UI Framework
The UI was built using SwiftUI.
### Dependency management
All of the dependencies are managed by SPM, compatible to the latest versions respectively.
### Unit tests
Unit tests were implemented using SwiftTesting, focused on View models, Data Objects and Service, in order to detect formatting issues, loading misbehavior and API contract inconsistencies.

Mock services are provided based in json string for better consistency checking and easily test scenario update, either manually or via pipeline scripts.

## Running
To run the project, make sure the local main branch is updated with the remote and if possible use Xcode's latest version.

OpenAI API key must be provided as a scheme OPENAI_API_KEY running argument.

Before compiling, update SPM's dependencies; If any dependency error occurs, cleaning the cache is recommended.

## Core Features
- Audio Recording
	- Capture short audio clips from the microphone with AVAudioSession/AVAudioRecorder (or AVAudioEngine if you prefer). ⚠️
	- Handle runtime permission flows and interruptions (phone calls, Siri, etc.). ✅
	- Persist recordings temporarily as files suitable for upload (e.g., .m4a). ✅
- Transcription
	- Send the recorded audio to a transcription API and display the returned text as
the user’s input. ⚠️
	- You may use Apple’s Speech framework or a hosted transcription service such
as OpenAI’s transcription API (Whisper) ✅
- LLM Completion
	- Send the transcribed text to a chat completion API and display the AI’s response. ✅
- UI
	- Present a simple conversation-like interface showing user messages
(transcriptions) and AI messages (LLM responses). ✅
	- Indicate loading/progress for API calls and show error states with retry. ✅
- App Architecture
	- Use SwiftUI for all user interfaces. ✅
	- Use an architecture you are comfortable with (e.g., MVVM, MVC, etc.), but
structure your code as if you were building a scalable, production-ready app. ✅
	- Prioritize separation of concerns, clean code, and modularization where
appropriate. ✅
	- Show reasonable dependency injection ✅

## Architecture facts

- MVVM with ObservableObject: view model is the state holder, exposing UI state via @Published properties, Views can bind to them for automatic updates.

- Service abstraction via dependency injection: The interaction is encapsulated in a protocol, injected with @Injection property wrapper. This decouples the view model from the concrete service and makes it easier to test and swap implementations.

- Encapsulated I/O components:
	- SpeechSynthesizer (synthesizer) handles text-to-speech, exposing isSpeaking as a publisher and providing speak/stopSpeaking APIs. The view model observes it to reset playbackID when speaking ends.
	- SpeechRecognizer (recognizer) manages microphone capture and speech-to-text, exposing transcript, noiseLevel, and state as publishers. The view model reacts to these to update UI state and animations, and to control lifecycle (start/stop/reset).

- Async flows with structured concurrency: Methods like pressedSpeak() and releaseSpeak() are async and marked @MainActor where they update published state, ensuring UI safety. They wrap the end-to-end flow: start listening, collect transcript, submit to LLM, append messages, and trigger TTS on assistant responses.

- Reactive pipeline with Combine: The view model subscribes to publishers from synthesizer and recognizer, synchronizing with the main run loop and storing AnyCancellables. This bridges the lower-level components to the SwiftUI state.

- User experience state machine: A simple ConversationState enum (listening, loading, idle) drives UI rendering and user interaction. The view model transitions through these states during the speech/LLM cycle.

- Resilience and recovery:
   • View model captures failed messages on retryList to support resubmission.
   • errorMessage is surfaced to the UI and also spoken aloud via TTS for accessibility/feedback.
   • Simulator-friendly #if DEBUG branch seeds a default transcript for easier testing.

- UI affordances:
   • noiseLevel animation logic maps dB levels to a normalized visual value, enhancing the listening UI.
   • playbackID tags the currently spoken message for highlighting.

## Considerations
The transcription is implemented using native audio APIs, therefore file storage was not required.
Future enhancements would cover UI polishment (such as animations smoothing) and gesture conflicting scenarios stressing to add an extra layer on UI consistence assurance.