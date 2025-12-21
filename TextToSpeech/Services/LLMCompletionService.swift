//
//  LLMCompletionService.swift
//  TextToSpeech
//
//  Created by Victor Brittes on 13/12/25.

/// A service abstraction for submitting text completion requests to a Large Language Model.
///
/// Conformers implement the logic to send `LLMTextInput` to an LLM provider and
/// return the generated `LLMTextOutput`. Implementations may use async/await or
/// provide callback-based APIs to integrate with different parts of the app.
protocol LLMCompletionService {
    
    /// Submits a text completion request to the Large Language Model service.
    ///
    /// Use this async API to request a completion for the provided input and
    /// receive the generated output or an error.
    /// - Parameter completion: The input payload containing the prompt and any
    ///   related configuration required by the LLM.
    /// - Returns: The generated `LLMTextOutput` from the model.
    /// - Throws: An error if the request fails or the response cannot be decoded.
    func submit(completion: LLMTextInput) async throws -> LLMTextOutput

}

