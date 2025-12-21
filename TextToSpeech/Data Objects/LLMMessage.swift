//
//  LLMMessage.swift
//  TextToSpeech
//
//  Created by Victor Brittes on 13/12/25.
//

import Combine
import Foundation

/// A single Large Language Model (LLM) chat message.
///
/// This model represents one message in a conversation between a `user` and an
/// `assistant`. It is observable for UI updates, identifiable for list diffing,
/// and codable for persistence or network transport.
///
/// Conformances:
/// - `ObservableObject`: Enables SwiftUI views to react to changes.
/// - `Identifiable`: Provides a stable `id` for lists and collections.
/// - `Codable` (nonisolated): Allows encoding/decoding across concurrency domains.
///
/// Properties:
/// - `id`: Unique identifier for the message.
/// - `role`: The speaker role (`user` or `assistant`).
/// - `content`: The textual content of the message.
class LLMMMessage: ObservableObject, Identifiable, nonisolated Codable {
    
    /// The role of the message author within the conversation.
    enum Role: String, Codable, Sendable {
        case assistant
        case user
    }
    
    /// Stable unique identifier used for diffing and identity.
    var id = UUID()
    
    /// The speaker role associated with this message (e.g., `.user`, `.assistant`).
    var role:  Role
    
    /// The raw text content of the message.
    var content: String
    
    /// Creates a new message.
    /// - Parameters:
    ///   - role: The author role for this message.
    ///   - content: The text content of the message.
    public init(role: Role,
                content: String) {
        self.role = role
        self.content = content
    }
}

extension LLMMMessage: Equatable {
    /// Compares messages by their unique identifier.
    static func == (lhs: LLMMMessage, rhs: LLMMMessage) -> Bool {
        lhs.id == rhs.id
    }
}

