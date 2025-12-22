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

/// A simple wrapper around AVSpeechSynthesizer that speaks text and publishes speaking state.
/// - Uses NaturalLanguage to pick an appropriate voice language when possible.
/// - Manages the AVAudioSession to duck other audio during playback.
class SpeechSynthesizer: NSObject, ObservableObject, @unchecked Sendable {
    /// The underlying AVFoundation speech synthesizer.
    private let synthesizer: AVSpeechSynthesizer

    /// Tracks the utterance currently being spoken to correlate delegate callbacks.
    private var currentUtterance: AVSpeechUtterance?
    
    /// Publishes whether the synthesizer is actively speaking.
    @Published private(set) var isSpeaking: Bool = false

    /// Initializes the speech synthesizer and sets up the delegate.
    override init() {
        synthesizer = AVSpeechSynthesizer()
        super.init()
        synthesizer.delegate = self
    }

    /// Speaks the provided text using AVSpeechSynthesizer.
    /// - Parameters:
    ///   - text: The text to be spoken.
    ///   - id: An identifier for the request (not persisted), useful if callers correlate utterances.
    ///
    /// If already speaking, this stops the current utterance before starting the new one.
    /// Attempts to detect the language of the text and select a matching voice.
    /// Configures the audio session to `.playback` and ducks other audio during speech.
    func speak(text: String) {
        if isSpeaking {
            stopSpeaking()
        }

        // Create an utterance from the input text.
        let utterance = AVSpeechUtterance(string: text)
        
        // Try to pick a voice that matches the dominant language of the text.
        if let language = self.detectLanguageOf(text: text) {
            utterance.voice = AVSpeechSynthesisVoice(language: language.rawValue)
        }

        // Configure audio to play back speech and duck other audio sources while speaking.
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true, options: [])

        synthesizer.speak(utterance)
        currentUtterance = utterance
    }

    /// Stops speaking immediately and deactivates the audio session.
    func stopSpeaking() {
        currentUtterance = nil
        isSpeaking = false
        synthesizer.stopSpeaking(at: .immediate)
        try? AVAudioSession.sharedInstance().setActive(false, options: [])
    }
    
    /// Attempts to detect the dominant language of the given text.
    /// - Parameter text: The text to analyze.
    /// - Returns: The detected `NLLanguage`, or `nil` if no dominant language could be determined.
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
    /// AVSpeechSynthesizerDelegate: Called when speech begins for an utterance.
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isSpeaking = true
    }

    /// AVSpeechSynthesizerDelegate: Called when speech finishes for an utterance.
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if utterance == currentUtterance {
            // Animate UI changes tied to speaking state transitions.
            withAnimation {
                isSpeaking = false
            }
        }
    }
}
