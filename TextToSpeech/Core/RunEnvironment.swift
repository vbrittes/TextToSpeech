//
//  RunEnvironment.swift
//  TextToSpeech
//
//  Created by Victor Brittes on 23/12/25.
//

import Foundation

enum RunEnvironment: String {
    
    case openAIKey = "OPENAI_API_KEY"
    
    var value: String {
        switch self {
        case .openAIKey:
            guard let value = ProcessInfo.processInfo.environment[rawValue] else {
                #if DEBUG
                fatalError("Undefined environment variable: \(rawValue)")
                #else
                return ""
                #endif
            }
            
            return value
        }
    }
}
