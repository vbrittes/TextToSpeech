//
//  ConversarionViewModelTests.swift
//  TextToSpeechTests
//
//  Created by Victor Brittes on 19/12/25.
//

import Testing
@testable import TextToSpeech
internal import Foundation

@MainActor
struct ConversarionViewModelTests {
    
    @Test func speakReleasing() async throws {
        let sut = ConversationViewModel(service: LLMCompletionMockService())
        
        #expect(sut.greeting == "How can I help you today?")
        
        await sut.send(message: "Hello world")
        
        #expect(sut.transcript.isEmpty)
        #expect(sut.messages.count == 2)
        #expect(sut.messages.first?.content == "Hello world")
        #expect(sut.messages.last?.content == "Hello! How can I help you today?")
        #expect(sut.errorMessage == nil)
        
        #expect(sut.greeting == nil)
    }
    
    @Test func failingFeedback() async throws {
        let conditionedService = LLMCompletionConditionedService()
        
        let sut = ConversationViewModel(service: conditionedService)
        
        await sut.send(message: "Hello world")
        
        conditionedService.success = false
        
        await sut.send(message: "Good bye world")
        
        #expect(sut.transcript.isEmpty)
        #expect(sut.messages.count == 3)
        #expect(sut.messages.last?.content == "Good bye world")
        #expect(sut.errorMessage == "Oops!")
    }

}

extension ConversationViewModel {
    @MainActor
    func send(message: String) async {
        var mock: LLMMMessage = await .mock()
        mock.content = message
        
        await retry(message: mock)
    }
}

class LLMCompletionConditionedService: LLMCompletionService {
    
    enum LLMError: Error, LocalizedError {
        case defaultError
        
        var errorDescription: String? {
            return "Oops!"
        }
    }
    
    var success = true
    
    let mockService = LLMCompletionMockService()
    
    func submit(completion: LLMTextInput) async throws -> LLMTextOutput {
        guard !success else {
            return try await mockService.submit(completion: completion)
        }
            
        try await Task.sleep(nanoseconds: 100_000_000)
        
        throw LLMError.defaultError
    }
    
}

extension LLMMMessage {
    @MainActor
    static func mock() async -> LLMMMessage {
        let mockService = LLMCompletionMockService()
        
        let input = LLMTextInput(model: .gpt4oMini, messages: [])
        let result = try! await mockService.submit(completion: input)
        
        return result.choices.first!.message
    }
}
