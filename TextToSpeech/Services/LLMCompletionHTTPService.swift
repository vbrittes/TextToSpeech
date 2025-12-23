//
//  LLMCompletionHTTPService.swift
//  TextToSpeech
//
//  Created by Victor Brittes on 16/12/25.
//

import Alamofire
import Foundation

class LLMCompletionHTTPService: LLMCompletionService, HTTPPerformer {
    private let openAIURL = URL(string: "https://api.openai.com")!
    private let apiKey = Environment.openAIKey.value
        
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
