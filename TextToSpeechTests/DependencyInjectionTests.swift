//
//  DependencyInjectionTests.swift
//  TextToSpeechTests
//
//  Created by Victor Brittes on 19/12/25.
//

import Testing
@testable import TextToSpeech
internal import Foundation

struct DependencyInjectionTests {

    @Test func serviceInjection() async throws {
        @Injection var service1: LLMCompletionService
        #expect(service1 != nil) //if this one fails, fatal error occurs. checking for good
    }

}
