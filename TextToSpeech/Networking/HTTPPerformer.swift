//
//  HTTPPerformer.swift
//  TextToSpeech
//
//  Created by Victor Brittes on 13/12/25.
//


import Alamofire
import Foundation

protocol HTTPPerformer { }

/// Convenience utilities for types that perform HTTP requests.
///
/// This extension provides:
/// - A shared Alamofire `Session` via `http` for issuing requests.
/// - A `defaultHeader` with common HTTP headers used across requests.
/// - A helper to merge additional headers into the defaults.
/// - A JSON pretty-printer for logging/debugging raw response data.
extension HTTPPerformer {
    /// Shared Alamofire session used to perform HTTP requests.
    ///
    /// Defaults to `AF`, Alamofire's global shared `Session`.
    var http: Session {
        return AF
    }
    
    /// Default HTTP headers applied to requests.
    ///
    /// Currently sets the `Accept` header to request JSON responses.
    var defaultHeader: HTTPHeaders {
        return [
            "accept": "application/json",
        ]
    }
    
    /// Returns a merged set of HTTP headers by starting with `defaultHeader` and
    /// then applying any additional headers provided by the `additional` closure.
    ///
    /// Use this helper when a specific request needs to add or override headers
    /// on top of the shared defaults (for example, to include an authorization
    /// token or a custom content type) without duplicating common headers.
    ///
    /// - Parameter additional: A closure that returns extra `HTTPHeaders` to be
    ///   merged. If a header key already exists in `defaultHeader`, the value
    ///   provided here will override it.
    /// - Returns: The combined `HTTPHeaders` containing defaults plus any
    ///   additional entries.
    func defaultHeader(additional: () -> HTTPHeaders) -> HTTPHeaders {
        var header = defaultHeader
        
        additional().forEach { header.add($0) }
        return header
    }
    
    /// Converts raw JSON `Data` into a pretty-printed JSON `String` for logging.
    ///
    /// - Parameter data: The raw response data to format.
    /// - Returns: A human-readable JSON string if formatting succeeds; otherwise `nil`.
    func prettyPrintedJSON(from data: Data?) -> String? {
        guard let data = data else {
            return nil
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
            return String(data: prettyData, encoding: .utf8)
        } catch {
            print("Error formatting JSON: \(error.localizedDescription)")
            return nil
        }
    }
}

