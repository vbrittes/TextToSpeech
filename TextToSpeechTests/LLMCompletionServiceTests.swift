//
//  LLMCompletionServiceTests.swift
//  TextToSpeechTests
//
//  Created by Victor Brittes on 19/12/25.
//

import Testing
@testable import TextToSpeech
internal import Foundation

@MainActor
struct LLMCompletionServiceTests : ~Copyable {

    var sut: LLMCompletionService!
    
    @Test func deserialize() async throws {
        let message = LLMMMessage(role: .user, content: "Hello")
        let input = LLMTextInput(model: .grok4, messages: [message])
        
        let result = try await sut.submit(completion: input)
        #expect(result.choices.count == 1)
        #expect(result.choices.first?.message.content == "Hello! How can I help you today?")
        #expect(result.choices.first?.message.role == .assistant)
        #expect(result.choices.first?.message.id.uuidString.isEmpty == false)
    }
    
    @MainActor
    init() {
        sut = LLMCompletionMockService()
    }
    
    deinit {
        //teaddown
    }
    
//    @Test func httpService() async throws {
//        let sut = LLMCompletionHTTPService()
//        
//        let message = LLMMMessage(role: .user, content: "Hello")
//        let input = LLMTextInput(model: .gpt40, messages: [message])
//        
//        let result = try await sut.submit(completion: input)
//        #expect(result.choices.count == 1)
//        #expect(result.choices.first?.message.content == "Hello! How can I help you today?")
//        #expect(result.choices.first?.message.role == .assistant)
//        #expect(result.choices.first?.message.id.uuidString.isEmpty == false)
//    }

}

/*
 curl -sS -i https://api.x.ai/v1/chat/completions \
   -H "Content-Type: application/json" \
   -H "Authorization: Bearer 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" \
   -d '{
     "model":"grok-4-0709",
     "messages":[
       {"role":"user","content":[{"type":"text","text":"Hello"}]}
     ]
   }'
 */
