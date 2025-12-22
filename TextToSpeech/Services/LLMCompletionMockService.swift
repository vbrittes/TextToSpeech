//
//  LLMCompletionMockService.swift
//  TextToSpeech
//
//  Created by Victor Brittes on 17/12/25.
//

import Foundation

class LLMCompletionMockService: LLMCompletionService {
    
    /// Submits a mock LLM completion request and returns a canned response.
    ///
    /// This mock implementation simulates network latency by suspending for
    /// approximately 5 seconds before decoding a hard-coded JSON payload into
    /// `LLMTextOutput` using `JSONDecoder`.
    ///
    /// - Parameter completion: The input payload describing the user's prompt or
    ///   message for the LLM. In this mock, the value isn't used.
    /// - Returns: A decoded `LLMTextOutput` representing the assistant's reply.
    /// - Throws: Any decoding errors encountered while parsing the mock JSON.
    /// - Note: Intended for testing and UI development without hitting a real
    ///   backend service.
    func submit(completion: LLMTextInput) async throws -> LLMTextOutput {
        try await Task.sleep(nanoseconds: 5_000_000_000)
        
        let response = """
        {
          "choices": [
            {
              "message": {
                "id": "\(UUID().uuidString)",
                "role": "assistant",
                "content": "Hello! How can I help you today?"
              }
            }
          ]
        }
        """
        
        let result: LLMTextOutput = try response.decodeJSON()
        
        return result
    }
}

extension String {
    func decodeJSON<T: Decodable>(
        _ type: T.Type = T.self,
        decoder: JSONDecoder = JSONDecoder()
    ) throws -> T {
        guard let data = self.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "String is not valid UTF-8")
            )
        }
        return try decoder.decode(T.self, from: data)
    }
}

