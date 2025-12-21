//
//  LLMTextInput.swift
//  TextToSpeech
//
//  Created by Victor Brittes on 13/12/25.

/// A codable payload used to send text-generation requests to an LLM service.
///
/// This structure encapsulates the target `model`, the conversation `messages`, and
/// optional generation controls such as `stream` and `temperature`.
struct LLMTextInput: nonisolated Codable {
    
    /// Supported remote model identifiers for text generation.
    enum Model: String, Codable {
        case chatGPT4oMini = "gpt-4o-mini"
        case gpt40 = "openai/gpt-4o"
        case grok4 = "grok-4-latest"
    }
    
    /// The target LLM model to use for generation.
    var model: Model
    /// The ordered list of chat messages forming the prompt/context.
    var messages: [LLMMMessage]
    /// Whether to request a streaming response (if the service supports it).
    var stream = false
    /// Sampling temperature controlling randomness (0 = deterministic).
    var temperature = 0
}
