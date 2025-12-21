//
//  LLMCompletionHTTPService.swift
//  TextToSpeech
//
//  Created by Victor Brittes on 16/12/25.
//

import Alamofire
import Foundation

class LLMCompletionHTTPService: LLMCompletionService, HTTPPerformer {
    private let openAIURL = URL(string: "https://openrouter.ai/api/")!
    private let apiKey = "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"
        
    /*
     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
     */
    func submit(completion: LLMTextInput) async throws -> LLMTextOutput {
        
        let url = openAIURL.appending(path: "v1/chat/completions")

        let headers = defaultHeader { [
            .authorization(bearerToken: apiKey),
        ] }
                        
        let result = await http.request(url, method: .post, parameters: completion, encoder: JSONParameterEncoder.default, headers: headers)
            .cURLDescription { print($0) }
            .validate()
            .serializingDecodable(LLMTextOutput.self)
            .result
        
        do {
            return try result.get()
        } catch {
            throw error
        }
        
    }
    
}
