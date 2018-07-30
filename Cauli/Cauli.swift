//
//  Cauli.swift
//  Cauli
//
//  Created by Cornelius Horstmann on 11.07.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

public class Cauli {
  
    public let florets: [Floret]
    
    /// Performs initial Cauli setup and hooks itself into the [URL Loading System](https://developer.apple.com/documentation/foundation/url_loading_system).
    ///
    /// Call this as early as possible, preferred in the [application:didFinishLaunchingWithOptions:](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622921-application).
    static let setup: Void = {
        URLProtocol.registerClass(CauliURLProtocol.self)
        URLSessionConfiguration.cauliSwizzleDefaultSessionConfigurationGetter()
        
        return
    }()
    
    deinit {
        CauliURLProtocol.remove(delegate: self)
    }
    
    init(florets: [Floret]) {
        self.florets = florets
        CauliURLProtocol.add(delegate: self)
    }
    
}

// For now we don't add any custom implementation here
extension Cauli: CauliURLProtocolDelegate {
    
    func willRequest(_ record: Record) -> Record {
        return florets.reduce(record) { (record, floret) -> Record in
            floret.willRequest(record)
        }
    }
    
    func didRespond(_ record: Record) -> Record {
        return florets.reduce(record) { (record, floret) -> Record in
            floret.didRespond(record)
        }
    }
    
}
