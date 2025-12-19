//
//  LLMCompletionService.swift
//  TextToSpeech
//
//  Created by Victor Brittes on 13/12/25.
//

protocol LLMCompletionService {
    func submit(completion: LLMTextInput) async throws -> LLMTextOutput
}
