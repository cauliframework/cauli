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
import ObjectiveC

/// A `URLProtocol` that answers every request with a static JSON response,
/// so that the tests never hit the network.
///
/// `enable()` registers the protocol for `URLSession.shared` and injects it into
/// every `URLSessionConfiguration.default`, which is what `CauliURLProtocol` uses
/// to perform the actual request.
final class StubURLProtocol: URLProtocol {

    static let stubData = Data("{\"response\":\"ok\"}".utf8)

    // swiftlint:disable force_unwrapping
    private static let defaultConfigurationGetter = class_getClassMethod(URLSessionConfiguration.self, #selector(getter: URLSessionConfiguration.default))!
    private static let stubbedConfigurationGetter = class_getClassMethod(URLSessionConfiguration.self, #selector(URLSessionConfiguration.stubbedDefaultSessionConfiguration))!
    // swiftlint:enable force_unwrapping

    private static var isEnabled = false

    static func enable() {
        guard !isEnabled else { return }
        isEnabled = true
        URLProtocol.registerClass(StubURLProtocol.self)
        method_exchangeImplementations(defaultConfigurationGetter, stubbedConfigurationGetter)
    }

    static func disable() {
        guard isEnabled else { return }
        isEnabled = false
        method_exchangeImplementations(defaultConfigurationGetter, stubbedConfigurationGetter)
        URLProtocol.unregisterClass(StubURLProtocol.self)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
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
        configuration.protocolClasses = [StubURLProtocol.self] + (configuration.protocolClasses ?? [])
        return configuration
    }
}
