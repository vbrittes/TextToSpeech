//
//  DependencyInjection.swift
//  TextToSpeech
//
//  Created by Victor Brittes on 13/12/25.
//

@propertyWrapper
internal struct Injection<T> {
    private var storage: T?
    private var mocking: Bool
    
    init(mocking: Bool = false) {
        self.mocking = mocking
    }
    
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
            let service: LLMCompletionService
            service = mocking ? LLMCompletionMockService() : LLMCompletionHTTPService()
            
            return service as? T
        }
        return nil
    }
}
