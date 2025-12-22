# CSTV
This is a Challenge Project to assess the developer technical skills. 
Used integrations:
	- Native Audio Transcription to get the message for user interaction based on user Speech.
	- Native Speech Synthesizer to read LLM responses aloud.
	- LLM Completion responses are mocked for lack of (paid) ChatGPT API key for testing purposes.

## Libraries used
### Alamofire
Used to perform HTTP requests.
### SwiftUI

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

Before compiling, update SPM's dependencies; If any dependency error occurs, cleaning the cache is recommended.

## Core Features
- Audio Recording
	- Capture short audio clips from the microphone with AVAudioSession/AVAudioRecorder (or AVAudioEngine if you prefer). ⚠️
	- Handle runtime permission flows and interruptions (phone calls, Siri, etc.). ⚠️
	- Persist recordings temporarily as files suitable for upload (e.g., .m4a). ⚠️
- Transcription
	- Send the recorded audio to a transcription API and display the returned text as
the user’s input. ⚠️
	- You may use Apple’s Speech framework or a hosted transcription service such
as OpenAI’s transcription API (Whisper) ✅
- LLM Completion
	- Send the transcribed text to a chat completion API and display the AI’s response. ⚠️
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
