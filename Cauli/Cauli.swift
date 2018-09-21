//
//  Copyright (c) 2018 cauli.works
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
