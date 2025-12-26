//
//  ConversationViewModel.swift
//  TextToSpeech
//
//  Created by Victor Brittes on 13/12/25.
//

import SwiftUI
import Combine

final class ConversationViewModel: ObservableObject {
    
    @Published private(set) var messages: [LLMMMessage] = []
    private var synthesizer = SpeechSynthesizer()
    private let recognizer = SpeechRecognizer()
    
    @Injection private var service: LLMCompletionService
    
    private var cancellables: Set<AnyCancellable> = []
    
    @Published private(set) var transcript = ""
    @Published private(set) var errorMessage: String?
    @Published private(set) var greeting: String? = "How can I help you today?"
    @Published private(set) var noiseLevel: CGFloat = 0.0
    @Published private(set) var playbackID: UUID?
    @Published var state: ConversationState = .idle
    @Published private(set) var retryList: [LLMMMessage] = []
        
    init(service: LLMCompletionService? = nil) {
        self.service = service ?? self.service
        
        synthesizer.$isSpeaking
            .receive(on: RunLoop.main)
            .sink { [weak self] speaking in
                if !speaking {
                    self?.playbackID = nil
                }
            }
            .store(in: &cancellables)
        
        recognizer.$transcript
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                self?.transcript = text
            }
            .store(in: &cancellables)
        
        recognizer.$noiseLevel
            .receive(on: RunLoop.main)
            .sink { [weak self] noise in
                guard self?.recognizer.state == .listening else {
                    withAnimation {
                        self?.noiseLevel = 1
                    }
                    return
                }
                
                let noise = CGFloat(noise)
                
                let minLevel = -70.0
                let maxLevel = -1.0
                
                withAnimation {
                    let calculated = (1.6 - pow((noise - maxLevel) / (minLevel - maxLevel), 2))
                    self?.noiseLevel = calculated
                }
            }
            .store(in: &cancellables)
    }
    
    /// Requests microphone access from the user and returns the authorization result.
    ///
    /// This method suspends while prompting for permission via `SpeechRecognizer`.
    ///
    /// - Returns: `true` if microphone access is authorized; otherwise, `false`.
    /// - Note: Consider calling this early (e.g., on first launch or before recording) so that
    ///   the permission prompt does not interrupt the capture flow.
    ///
    func requestMicPermissionAccess() async -> Bool {
        return await recognizer.requestPermissions()
    }
    
    /// Begins a new speech recognition session.
    ///
    /// Resets the current recognizer state and attempts to start listening for audio input.
    /// Any error encountered is surfaced to `errorMessage` for UI presentation.
    ///
    /// - Note: Runs on the main actor because it updates observable properties bound to the UI.
    ///
    @MainActor
    func pressedSpeak() async {
        
        print("Listening...")
        
        if synthesizer.isSpeaking {
            stopReadingAloud()
        }
        
        state = .listening
        recognizer.reset()
                
        do {
            try await recognizer.startListening()
        } catch {
            errorMessage = "Could not start speech recognition"
        }
    }

    /// Finalizes the speech input and submits the user's transcript to the LLM service.
    ///
    /// Stops listening, clears the noise level, validates the transcript, appends the user's
    /// message to the conversation, and triggers a completion request. On success, assistant
    /// messages are appended and read aloud. On failure, an error is announced and the message
    /// is queued in `retryList`.
    ///
    /// - Important: Updates multiple published properties (`messages`, `loading`, `errorMessage`,
    ///   `greeting`, `playbackID`) and should remain on the main actor.
    ///
    @MainActor
    func releaseSpeak() async {
        
        ///enable testing on simulator
        #if DEBUG
        let transcript = self.transcript.isEmpty ? "a" : self.transcript
        #endif
        
        recognizer.stop()
        noiseLevel = 0
        print("Final transcript: \(transcript)")
        
        guard !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let message = LLMMMessage(role: .user, content: transcript)
        messages.append(message)
        
        recognizer.reset()
        
        let input = LLMTextInput(model: .gpt4oMini, messages: messages)
        
        greeting = nil
        
        errorMessage = nil
        state = .loading
        
        do {
            let result = try await service.submit(completion: input)
            
            withAnimation {
                result.choices.forEach { messages.append($0.message) }
                state = .idle
            }
            
            if let message = messages.last {
                readAloud(message: message)
            }
            
            self.service = service
            
            Task { @MainActor [weak self] in
                self?.transcript = ""
            }
            
        } catch {
            withAnimation {
                errorMessage = error.localizedDescription
                retryList.append(message)
                state = .idle
            }
            
            synthesizer.speak(text: error.localizedDescription)
            
            self.service = service
        }
    }
        
}

extension ConversationViewModel {
    
    var loading: Bool {
        state == .loading
    }
    
    /// Speaks the provided message content using the speech synthesizer.
    ///
    /// - Parameter message: The message whose `content` will be spoken. The message's `id`
    ///   is also used to tag playback so the UI can reflect the currently speaking item.
    ///
    func readAloud(message: LLMMMessage) {
        synthesizer.speak(text: message.content)
        Task { @MainActor in
            playbackID = message.id
        }
    }
    
    /// Stops any ongoing speech synthesis and clears the current playback identifier.
    ///
    /// Call this to immediately halt the voice output started by `readAloud(message:)`.
    /// This method also resets `playbackID` to `nil` so the UI can reflect that
    /// no message is currently being spoken.
    func stopReadingAloud() {
        synthesizer.stopSpeaking()
        playbackID = nil
    }
    
    /// Retries a previously failed message by re-submitting it to the LLM service.
    ///
    /// Removes the message from the conversation, places its content back into `transcript`,
    /// and invokes `releaseSpeak()` to follow the normal submission flow.
    ///
    /// - Parameter message: The message to retry.
    ///
    func retry(message: LLMMMessage) async {
        messages.removeAll { $0 == message }
        transcript = message.content
        await releaseSpeak()
    }
}

enum ConversationState {
    case listening, loading, idle
}

