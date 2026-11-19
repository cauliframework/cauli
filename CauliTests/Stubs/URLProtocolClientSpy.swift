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

/// Records every call a `URLProtocol` makes on its client, in order.
final class URLProtocolClientSpy: NSObject, URLProtocolClient {

    enum Event: Equatable {
        case redirect
        case response
        case data(Data)
        case finished
        case failed
    }

    private let lock = NSLock()
    private var recordedEvents: [Event] = []

    /// Called after each recorded event, on the thread the protocol called the client on.
    var onEvent: ((Event) -> Void)?

    var events: [Event] {
        lock.lock()
        defer { lock.unlock() }
        return recordedEvents
    }

    /// All data passed to the client, concatenated in the order it was delivered.
    var receivedData: Data {
        events.reduce(into: Data()) { result, event in
            if case .data(let data) = event {
                result.append(data)
            }
        }
    }

    private func record(_ event: Event) {
        lock.lock()
        recordedEvents.append(event)
        lock.unlock()
        onEvent?(event)
    }

    func urlProtocol(_ protocol: URLProtocol, wasRedirectedTo request: URLRequest, redirectResponse: URLResponse) {
        record(.redirect)
    }

    func urlProtocol(_ protocol: URLProtocol, cachedResponseIsValid cachedResponse: CachedURLResponse) {}

    func urlProtocol(_ protocol: URLProtocol, didReceive response: URLResponse, cacheStoragePolicy policy: URLCache.StoragePolicy) {
        record(.response)
    }

    func urlProtocol(_ protocol: URLProtocol, didLoad data: Data) {
        record(.data(data))
    }

    func urlProtocolDidFinishLoading(_ protocol: URLProtocol) {
        record(.finished)
    }

    func urlProtocol(_ protocol: URLProtocol, didFailWithError error: Error) {
        record(.failed)
    }

    func urlProtocol(_ protocol: URLProtocol, didReceive challenge: URLAuthenticationChallenge) {}

    func urlProtocol(_ protocol: URLProtocol, didCancel challenge: URLAuthenticationChallenge) {}
}
