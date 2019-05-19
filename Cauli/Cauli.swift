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

import UIKit

/// The Cauli class is the starting point of the Cauli framework.
/// Use the perconfigured `Cauli.shared` or create your own instance.
/// Please check the Readme.md for more information.
public class Cauli {

    /// The shared Cauli instance. This instance is fully configured with the default
    /// Florets. Make sure to call the `run()` function to start the instance.
    /// You can create a new Cauli instance with your own Configuration and Florets.
    public static let shared = Cauli([InspectorFloret()], configuration: Configuration.standard)

    /// The Storage used by this instance to store all Records.
    public let storage: Storage
    internal let florets: [Floret]
    private var enabledFlorets: [InterceptingFloret] {
        return florets.compactMap { $0 as? InterceptingFloret }.filter { $0.enabled }
    }
    private let configuration: Configuration
    private var viewControllerManager: ViewControllerShakePresenter?
    private var enabled: Bool = false

    deinit {
        CauliURLProtocol.remove(delegate: self)
    }

    /// Creates and returns a new Cauli instance.
    ///
    /// - Parameters:
    ///   - florets: The florets that should be used.
    ///   - configuration: The configuration.
    public init(_ florets: [Floret], configuration: Configuration) {
        Cauli.setup()
        self.florets = florets
        self.configuration = configuration
        self.storage = MemoryStorage(capacity: configuration.storageCapacity, preStorageRecordModifier: configuration.preStorageRecordModifier)
        CauliURLProtocol.add(delegate: self)
        loadConfiguration(configuration)
    }

    private func loadConfiguration(_ configuration: Configuration) {
        if configuration.enableShakeGesture {
            viewControllerManager = ViewControllerShakePresenter { [weak self] in
                self?.viewController()
            }
        }
    }

    /// The ViewController for the Cauli UI. For the shared Cauli instance,
    /// and if `enableShakeGesture` in the `Configuration` is set to true
    /// this ViewController will be shown when shaking the device.
    /// You can use this function to create a new ViewController and display it manually.
    /// **Attention:**
    /// This ViewController expects to be displayed in a navigation stack, as it can
    /// try to push other ViewControllers to the navigation stack.
    ///
    /// - Returns: A new, unretained ViewController.
    public func viewController() -> UIViewController {
        return CauliViewController(cauli: self)
    }

    /// Starts this Cauli instance.
    public func run() {
        enabled = true
    }

    /// Stops this Cauli instance.
    public func pause() {
        enabled = false
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
    private static func setup() {
        _ = _setup
    }
}

extension Cauli: CauliURLProtocolDelegate {
    func handles(_ record: Record) -> Bool {
        return enabled && configuration.recordSelector.selects(record)
    }

    func willRequest(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        assert(!Thread.current.isMainThread, "should never be called on the MainThread")
        guard enabled else { completionHandler(record); return }
        enabledFlorets.cauli_reduceAsync(record, transform: { record, floret, completion in
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
        assert(!Thread.current.isMainThread, "should never be called on the MainThread")
        guard enabled else { completionHandler(record); return }
        enabledFlorets.cauli_reduceAsync(record, transform: { record, floret, completion in
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
