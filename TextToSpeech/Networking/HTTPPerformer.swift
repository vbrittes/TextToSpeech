//
//  HTTPPerformer.swift
//  TextToSpeech
//
//  Created by Victor Brittes on 13/12/25.
//


import Alamofire
import Foundation

protocol HTTPPerformer {
}

extension HTTPPerformer {
    var http: Session {
        return AF
    }
    
    var defaultHeader: HTTPHeaders {
        return [
            "accept": "application/json",
        ]
    }
    
    func defaultHeader(additional: HTTPHeaders) {
        var header = defaultHeader
        
        additional.forEach { header.add($0) }
    }
    
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
