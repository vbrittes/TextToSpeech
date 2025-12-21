//
//  LLMTextOutput.swift
//  TextToSpeech
//
//  Created by Victor Brittes on 13/12/25.
//

/// A model representing the text output returned by a Large Language Model (LLM).
///
/// This type mirrors the top-level payload in an LLM response where the
/// generated alternatives are exposed under a `choices` array.
///
/// The struct is marked `nonisolated` to indicate it can be safely used from
/// any concurrency context without requiring isolation to an actor. It also
/// conforms to `Codable` for easy JSON encoding/decoding.
///
struct LLMTextOutput: nonisolated Codable {
    
    /// The list of generated alternatives produced by the LLM.
    var choices: [LLMChoice]
    
}

