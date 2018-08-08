//
//  Cauli.swift
//  Cauli
//
//  Created by Cornelius Horstmann on 11.07.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

public class Cauli {
  
    private let storage: Storage = MemoryStorage()
    public let florets: [Floret]
    
    deinit {
        CauliURLProtocol.remove(delegate: self)
    }
    
    public init(florets: [Floret]) {
        self.florets = florets
        CauliURLProtocol.add(delegate: self)
    }
}

extension Cauli {
    // We use this static property here to ensure the actual setup
    // is performed only once
    private static let setup: Void = {
        URLProtocol.registerClass(CauliURLProtocol.self)
        URLSessionConfiguration.cauliSwizzleDefaultSessionConfigurationGetter()
        return
    }()
    
    /// Performs initial Cauli setup and hooks itself into the [URL Loading System](https://developer.apple.com/documentation/foundation/url_loading_system).
    ///
    /// Call this as early as possible, preferred in the [application:didFinishLaunchingWithOptions:](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622921-application).
    public func setup() {
        _ = setup
    }
}

// For now we don't add any custom implementation here
extension Cauli: CauliURLProtocolDelegate {
    
    func willRequest(_ record: Record) -> Record {
        let modifiedRecord = florets.reduce(record) { (record, floret) -> Record in
            floret.willRequest(record)
        }
        storage.store(modifiedRecord)
        return modifiedRecord
    }
    
    func didRespond(_ record: Record) -> Record {
        let modifiedRecord =  florets.reduce(record) { (record, floret) -> Record in
            floret.didRespond(record)
        }
        storage.store(modifiedRecord)
        return modifiedRecord
    }
    
}
