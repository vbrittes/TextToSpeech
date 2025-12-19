//
//  DependencyInjection.swift
//  TextToSpeech
//
//  Created by Victor Brittes on 13/12/25.
//

@propertyWrapper
internal struct Injection<T> {
    private var storage: T?
    
    var wrappedValue: T {
        mutating get {
            if let storage {
                return storage
            }
            
            guard let f = factory else {
                fatalError("injection not implemente")
            }
            
            storage = f
            
            return f
        }
        set {
            storage = newValue
        }
    }
    
    private var factory: T? {
        if T.self == (any LLMCompletionService).self {
            return LLMCompletionHTTPService() as? T
        }
        return nil
    }
}
