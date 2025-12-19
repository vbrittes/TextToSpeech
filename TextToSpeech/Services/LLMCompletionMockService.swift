//
//  LLMCompletionMockService.swift
//  TextToSpeech
//
//  Created by Victor Brittes on 17/12/25.
//

import Foundation

class LLMCompletionMockService: LLMCompletionService {
    
    func submit(completion: LLMTextInput) async throws -> LLMTextOutput {
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let response = """
        {
          "choices": [
            {
              "message": {
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
