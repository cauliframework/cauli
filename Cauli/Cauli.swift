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
    private static let _setup: Void = {
        URLProtocol.registerClass(CauliURLProtocol.self)
        URLSessionConfiguration.cauliSwizzleDefaultSessionConfigurationGetter()
        return
    }()

    /// Performs initial Cauli setup and hooks itself into the [URL Loading System](https://developer.apple.com/documentation/foundation/url_loading_system).
    ///
    /// Call this as early as possible, preferred in the [application:didFinishLaunchingWithOptions:](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622921-application).
    public static func setup() {
        _ = _setup
    }
}

extension Cauli: CauliURLProtocolDelegate {
    func willRequest(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        florets.cauli_reduceAsync(record, transform: { record, floret, completion in
            floret.willRequest(record) { record in
                completion(record)
            }
        }, completion: { record in
            DispatchQueue.main.sync {
                self.storage.store(record)
            }
            completionHandler(record)
        })
    }

    func didRespond(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        florets.cauli_reduceAsync(record, transform: { record, floret, completion in
            floret.didRespond(record) { record in
                completion(record)
            }
        }, completion: { record in
            DispatchQueue.main.sync {
                self.storage.store(record)
            }
            completionHandler(record)
        })
    }

}
