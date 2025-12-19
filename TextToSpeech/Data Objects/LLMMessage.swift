//
//  LLMMessage.swift
//  TextToSpeech
//
//  Created by Victor Brittes on 13/12/25.
//

import Combine
import Foundation

class LLMMMessage: ObservableObject, Identifiable, nonisolated Codable {
    
    enum Role: String, Codable, Sendable {
        case assistant
        case user
    }
    
    enum CodingKeys: String, CodingKey {
        case role, content
    }
    
    var id = UUID()
    var role:  Role
    var content: String
    
    public init(role: Role,
                content: String) {
        self.role = role
        self.content = content
    }
}

extension LLMMMessage: Equatable {
    static func == (lhs: LLMMMessage, rhs: LLMMMessage) -> Bool {
        lhs.id == rhs.id
    }
}
