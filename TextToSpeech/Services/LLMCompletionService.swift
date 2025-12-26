//
//  LLMCompletionService.swift
//  TextToSpeech
//
//  Created by Victor Brittes on 13/12/25.

import Foundation
import Alamofire

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

/// A user-friendly networking error wrapper used to surface readable messages.
///
/// Maps HTTP status codes and underlying errors into high-level categories that
/// the UI can present. Conforms to `LocalizedError` to provide an end-user facing
/// `errorDescription`.
enum FriendlyNetworkingError: Error, LocalizedError {
    /// Client-side or request configuration error (4xx), such as invalid credentials.
    /// - Parameter underlying: The original error returned by the networking layer.
    case serviceMissbehavior(underlying: Error)
    /// Server-side failure (typically 5xx).
    /// - Parameter underlying: The original error returned by the networking layer.
    case unexpectedError(underlying: Error)
    /// Connectivity or transport issue (no response code or outside handled ranges).
    /// - Parameter underlying: The original error returned by the networking layer.
    case connectionFailed(underlying: Error)
    
    /// Resolves a `FriendlyNetworkingError` from an optional HTTP status code and an underlying error.
    ///
    /// - Parameters:
    ///   - code: The HTTP status code, if available. 4xx maps to `.serviceMissbehavior`, 500 maps to `.unexpectedError`,
    ///           and any other value (including `nil`) maps to `.connectionFailed`.
    ///   - error: The underlying error to wrap.
    /// - Returns: A categorized `FriendlyNetworkingError` suitable for display to the user.
    static func solve(code: Int?, error: Error) -> Self {
        let code = code ?? 0 //connection failed if no error
        
        if (400..<500).contains(code) {
            return .serviceMissbehavior(underlying: error)
        } else if code == 500 {
            return .unexpectedError(underlying: error)
        } else {
            return .connectionFailed(underlying: error)
        }
    }
    
    /// A short, localized description intended for end-user presentation.
    var errorDescription: String? {
        switch self {
        case .serviceMissbehavior:
            return "AI integration failed. Check your credentials."
        case .unexpectedError:
            return "An unexpected error occurred."
        case .connectionFailed:
            return "A network error occurred. Please try again later."
        }
    }
}

/// Convenience utilities for converting Alamofire errors into user-friendly categories.
extension AFError {
    /// A mapped `FriendlyNetworkingError` derived from this `AFError`.
    ///
    /// Uses the `responseCode` (if present) and the error itself to categorize
    /// the failure via `FriendlyNetworkingError.solve(code:error:)`.
    /// - Returns: A categorized error if mapping is possible; otherwise `nil`.
    var friendlyError: FriendlyNetworkingError? {
        return .solve(code: responseCode, error: self)
    }
}
