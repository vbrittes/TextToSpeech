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
    
    @Injection(mocking: false) private var service: LLMCompletionService
    
    private var cancellables: Set<AnyCancellable> = []
    
    @Published private(set) var transcript = ""
    @Published private(set) var errorMessage: String?
    @Published private(set) var greeting: String? = "How can I help you today?"
    @Published private(set) var noiseLevel: CGFloat = 0.0
    @Published private(set) var playbackID: UUID?
    @Published private(set) var loading = false
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
                
                let minLevel = -60.0
                let maxLevel = -10.0
                
                withAnimation {
                    self?.noiseLevel = 2 - pow((noise - maxLevel) / (minLevel - maxLevel), 2)
                }
            }
            .store(in: &cancellables)
    }
    
    func requestMicPermissionAccess() async {
        _ = await recognizer.requestMicrophonePermission()
    }
    
    @MainActor
    func pressedSpeak() async {
        print("Listening...")
        
        recognizer.reset()
                
        do {
            try await recognizer.startListening()
        } catch {
            errorMessage = "Could not start speech recognition"
        }
    }

    @MainActor
    func releaseSpeak() async {
        transcript = "a"
        
        recognizer.stop()
        noiseLevel = 0
        print("Final transcript: \(transcript)")
        
        guard !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let message = LLMMMessage(role: .user, content: transcript)
        let input = LLMTextInput(model: .grok4, messages: [message])
        
        withAnimation {
            greeting = nil
            messages.append(message)
            
            transcript = ""
            
            errorMessage = nil
            loading = true
        }
        
        do {
            let result = try await service.submit(completion: input)
            
            recognizer.reset()
            
            withAnimation {
                result.choices.forEach { messages.append($0.message) }
                loading = false
            }
            
            if let message = result.choices.first?.message {
                readAloud(message: message)
            }
            
            @Injection(mocking: false) var service: LLMCompletionService
            self.service = service
            
        } catch {
            withAnimation {
                errorMessage = error.localizedDescription
                retryList.append(message)
                loading = false
            }
            
            synthesizer.speak(text: error.localizedDescription, id: UUID())
            
            @Injection(mocking: true) var service: LLMCompletionService
            self.service = service
        }
    }
        
}

extension ConversationViewModel {
    func readAloud(message: LLMMMessage) {
        synthesizer.speak(text: message.content, id: message.id)
        playbackID = message.id
    }
    
    func retry(message: LLMMMessage) async {
        messages.removeAll { $0 == message }
        transcript = message.content
        await releaseSpeak()
    }
}
