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
        let input = LLMTextInput(model: .gpt40, messages: [message])
        
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
    
    ///this test is for integration purposes
//    @Test func httpService() async throws {
//        let sut = LLMCompletionHTTPService()
//        
//        let message = LLMMMessage(role: .user, content: "Hello")
//        let input = LLMTextInput(model: .gpt4oMini, messages: [message])
//        
//        let result = try await sut.submit(completion: input)
//        #expect(result.choices.count == 1)
//        #expect(result.choices.first?.message.content.isEmpty == false)
//        #expect(result.choices.first?.message.role == .assistant)
//        #expect(result.choices.first?.message.id.uuidString.isEmpty == false)
//    }

}
