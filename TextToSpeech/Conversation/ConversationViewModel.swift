//
//  ConversationViewModel.swift
//  TextToSpeech
//
//  Created by Victor Brittes on 13/12/25.
//

import SwiftUI
import Combine

final class ConversationViewModel: ObservableObject {
    
    @Published var messages: [LLMMMessage] = []
    @Published var noiseMeter = RecorderNoiseMeter()
    private var synthesizer = SpeechSynthesizer()
    private let recognizer = SpeechRecognizer()
    
    @Injection private var service: LLMCompletionService
    
    private var cancellables: Set<AnyCancellable> = []
    
    @Published var transcript = ""
    @Published var errorMessage: String?
    @Published var greeting: String? = "How can I help you today?"
    @Published var noiseLevel: CGFloat = 0.0
    
    init(service: LLMCompletionService? = nil) {
        self.service = service ?? self.service
        
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
                    self?.noiseLevel = 1
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
        recognizer.stop()
        noiseLevel = 0
        print("Final transcript: \(transcript)")
        
        guard !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let message = LLMMMessage(role: .user, content: transcript)
        let input = LLMTextInput(model: .grok4, messages: [message])
        
        greeting = nil
        messages.append(message)
        
        transcript = ""
        
        do {
            errorMessage = nil
            
            let result = try await service.submit(completion: input)
            result.choices.forEach { messages.append($0.message) }
            
            recognizer.reset()
            
            if let message = result.choices.first?.message {
                synthesizer.speak(text: message.content, id: message.id)
            }
            
        } catch {
            errorMessage = error.localizedDescription
            synthesizer.speak(text: error.localizedDescription, id: UUID())
        }
    }
        
}

