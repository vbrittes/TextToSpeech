//
//  SpeechSynthesizer.swift
//  TextToSpeech
//
//  Created by Victor Brittes on 15/12/25.
//

import Combine
import NaturalLanguage
import AVFoundation
import SwiftUI

class SpeechSynthesizer: NSObject, ObservableObject, @unchecked Sendable {
    private let synthesizer: AVSpeechSynthesizer
    private var currentUtterance: AVSpeechUtterance?
    
    @Published private(set) var isSpeaking: Bool = false

    override init() {
        synthesizer = AVSpeechSynthesizer()
        super.init()
        synthesizer.delegate = self
    }

    func speak(text: String, id: UUID) {
        if isSpeaking {
            stopSpeaking()
        }

        let utterance = AVSpeechUtterance(string: text)
        
        if let language = self.detectLanguageOf(text: text) {
            utterance.voice = AVSpeechSynthesisVoice(language: language.rawValue)
        }

        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true, options: [])

        synthesizer.speak(utterance)
        currentUtterance = utterance
    }

    func stopSpeaking() {
        currentUtterance = nil
        isSpeaking = false
        synthesizer.stopSpeaking(at: .immediate)
        try? AVAudioSession.sharedInstance().setActive(false, options: [])
    }
    
    private func detectLanguageOf(text: String) -> NLLanguage? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        guard let language = recognizer.dominantLanguage else {
            return nil
        }
        
        return language
    }
}

extension SpeechSynthesizer: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isSpeaking = true
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if utterance == currentUtterance {
            withAnimation {
                isSpeaking = false
            }
        }
    }
}
