//
//  Cauli.swift
//  Cauli
//
//  Created by Cornelius Horstmann on 11.07.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

public class Cauli {
    
    /// Performs initial Cauli setup and hooks itself into the [URL Loading System](https://developer.apple.com/documentation/foundation/url_loading_system).
    /// Call this function as early as possible, preferred in the [application:didFinishLaunchingWithOptions:](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622921-application).
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
