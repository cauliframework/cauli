//
//  Cauli.swift
//  Cauli
//
//  Created by Cornelius Horstmann on 11.07.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

public class Cauli {
    /// This will hook Cauli into the [URL Loading System](https://developer.apple.com/documentation/foundation/url_loading_system)
    /// by register a custom [URLProtocol](https://developer.apple.com/documentation/foundation/urlprotocol)
    /// and swizzling the [URLSessionConfiguration.default](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/1411560-default) with one,
    /// where the [protocolClasses](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/1411050-protocolclasses)
    /// contain the custom [URLProtocol](https://developer.apple.com/documentation/foundation/urlprotocol).
    /// - Attention: It is recommended to call `Cauli.setup()` as soon as possible.
    /// Otherwise there might already exist a custom [URLSessionConfiguration](https://developer.apple.com/documentation/foundation/urlsessionconfiguration)
    /// which does not consider our custom [URLProtocol](https://developer.apple.com/documentation/foundation/urlprotocol).
    public func setup() {
        URLProtocol.registerClass(CauliURLProtocol.self)
        URLSessionConfiguration.cauliSwizzleDefaultSessionConfigurationGetter()
    }
    
    deinit {
        CauliURLProtocol.remove(delegate: self)
    }
    
    init() {
        CauliURLProtocol.add(delegate: self)
    }
    
}

// For now we don't add any custom implementation here
extension Cauli: CauliURLProtocolDelegate {
    func canHandle(_ request: URLRequest) -> Bool {
        // TODO: implement me
        return false
    }
    
    func willRequest(_ record: Record) -> Record {
        // TODO: implement me
        return record
    }
    
    func didRespond(_ record: Record) -> Record {
        // TODO: implement me
        return record
    }
}
