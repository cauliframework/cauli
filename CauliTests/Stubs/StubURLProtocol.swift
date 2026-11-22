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

@testable import Cauliframework
import Foundation
import ObjectiveC

/// A `URLProtocol` that answers every request with a static JSON response,
/// so that the tests never hit the network.
///
/// `enable()` injects the protocol into every `URLSessionConfiguration.default`,
/// directly after the `CauliURLProtocol` if it is there. This way a session created
/// with `.default` is still intercepted by Cauli first, and the session the
/// `CauliURLProtocol` uses to perform the actual request is answered by the stub.
///
/// It composes with Cauli's own swizzling of `URLSessionConfiguration.default`,
/// as long as that is installed before `enable()` is called.
final class StubURLProtocol: URLProtocol {

    static let stubData = Data("{\"response\":\"ok\"}".utf8)

    /// Requests to this url are never answered, e.g. to let them time out.
    static let hangingURL = URL(string: "https://hanging.stub.cauli.works")! // swiftlint:disable:this force_unwrapping
    /// Called when a request to the `hangingURL` reached the stub.
    static var hangingRequestStarted: (() -> Void)?

    // swiftlint:disable force_unwrapping
    private static let defaultConfigurationGetter = class_getClassMethod(URLSessionConfiguration.self, #selector(getter: URLSessionConfiguration.default))!
    private static let stubbedConfigurationGetter = class_getClassMethod(URLSessionConfiguration.self, #selector(URLSessionConfiguration.stubbedDefaultSessionConfiguration))!
    // swiftlint:enable force_unwrapping

    private static var isEnabled = false

    static func enable() {
        guard !isEnabled else { return }
        isEnabled = true
        method_exchangeImplementations(defaultConfigurationGetter, stubbedConfigurationGetter)
    }

    static func disable() {
        guard isEnabled else { return }
        isEnabled = false
        method_exchangeImplementations(defaultConfigurationGetter, stubbedConfigurationGetter)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        if request.url?.host == StubURLProtocol.hangingURL.host {
            StubURLProtocol.hangingRequestStarted?()
            return
        }
        guard let url = request.url,
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"]) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: StubURLProtocol.stubData)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

extension URLSessionConfiguration {
    @objc class func stubbedDefaultSessionConfiguration() -> URLSessionConfiguration {
        let configuration = stubbedDefaultSessionConfiguration() // since it is swizzled, this calls the original implementation
        var protocolClasses = configuration.protocolClasses ?? []
        let stubIndex = protocolClasses.firstIndex { $0 == CauliURLProtocol.self }.map { $0 + 1 } ?? 0
        protocolClasses.insert(StubURLProtocol.self, at: stubIndex)
        configuration.protocolClasses = protocolClasses
        return configuration
    }
}
