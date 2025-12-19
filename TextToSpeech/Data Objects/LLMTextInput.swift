//
//  LLMTextInput.swift
//  TextToSpeech
//
//  Created by Victor Brittes on 13/12/25.
//

struct LLMTextInput: nonisolated Codable {
    
    enum Model: String, Codable {
        case chatGPT4oMini = "gpt-4o-mini"
        case gpt40 = "openai/gpt-4o"
        case grok4 = "grok-4-latest"
    }
    
    var model: Model
    var messages: [LLMMMessage]
    var stream = false
    var temperature = 0
}
