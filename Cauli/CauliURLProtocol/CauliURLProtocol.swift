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

internal class CauliURLProtocol: URLProtocol {
    private lazy var executingURLSession: URLSession = {
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.protocolClasses = sessionConfiguration.protocolClasses?.filter { $0 != CauliURLProtocol.self }
        return URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    }()

    private static var weakDelegates: [WeakReference<CauliURLProtocolDelegate>] = []
    private static var delegates: [CauliURLProtocolDelegate] {
        let nonNilDelegates = weakDelegates.filter { $0.value != nil }
        return nonNilDelegates.compactMap { $0.value as? CauliURLProtocolDelegate }
    }

    private var record: Record
    private var dataTask: URLSessionDataTask?
    private var authenticationChallengeProxy: CauliAuthenticationChallengeProxy?

    internal static func add(delegate: CauliURLProtocolDelegate) {
        weakDelegates.append(WeakReference(delegate))
    }

    internal static func remove(delegate: CauliURLProtocolDelegate) {
        weakDelegates = weakDelegates.filter { $0.value !== delegate }
    }

    override init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        record = Record(request)
        super.init(request: request, cachedResponse: cachedResponse, client: client)
    }
}

// Overriding URLProtocol functions
extension CauliURLProtocol {

    override class func canInit(with task: URLSessionTask) -> Bool {
        var handles = false
        if let request = task.currentRequest ?? task.originalRequest {
            handles = self.handles(Record(request))
        }
        return task is URLSessionDataTask && !delegates.isEmpty && handles
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return !delegates.isEmpty && handles(Record(request))
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        willRequest(record) { record in
            self.record = record
            self.record.requestStarted = Date()
            if case .result(_)? = record.result {
                self.urlSession(didCompleteWithError: nil)
            } else if case let .error(error)? = record.result {
                self.urlSession(didCompleteWithError: error)
            } else {
                self.dataTask = self.executingURLSession.dataTask(with: self.record.designatedRequest)
                self.dataTask?.resume()
            }
        }
    }

    override func stopLoading() {
        dataTask?.cancel()
        invalidateURLSession()
    }
}

extension CauliURLProtocol: URLSessionDelegate, URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        record.result = .result(Response(response, data: nil))
        completionHandler(.allow)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive receivedData: Data) {
        if CauliURLProtocol.handles(record) {
            try? record.append(receivedData: receivedData)
        } else {
            if case let .result(response)? = record.result, let data = response.data {
                self.client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocol(self, didLoad: receivedData)
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        urlSession(didCompleteWithError: error)
    }

    private func urlSession(didCompleteWithError error: Error?) {
        invalidateURLSession()
        if let error = error {
            record.result = .error(error as NSError)
        }

        didRespond(record) { record in
            self.record = record
            self.record.responseReceived = Date()
            switch record.result {
            case let .result(response)?:
                self.client?.urlProtocol(self, didReceive: response.urlResponse, cacheStoragePolicy: .allowed)
                if let data = response.data {
                    self.client?.urlProtocol(self, didLoad: data)
                }
                self.client?.urlProtocolDidFinishLoading(self)
            case .error(let error)?:
                self.client?.urlProtocol(self, didFailWithError: error)
            case nil:
                self.client?.urlProtocol(self, didFailWithError: NSError(domain: "FIXME", code: 0, userInfo: [:]))
            }
        }
    }

    @available(iOS 10.0, *)
    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        // possibly add the metrics to the record in the future
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let authenticationChallengeProxy = CauliAuthenticationChallengeProxy(authChallengeCompletionHandler: completionHandler)
        let proxiedChallenge = URLAuthenticationChallenge(authenticationChallenge: challenge, sender: authenticationChallengeProxy)
        self.authenticationChallengeProxy = authenticationChallengeProxy
        client?.urlProtocol(self, didReceive: proxiedChallenge)
    }
}

extension CauliURLProtocol {
    private class func handles(_ record: Record) -> Bool {
        return delegates.reduce(false) { result, delegate in
            result || delegate.handles(record)
        }
    }

    private func willRequest(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        CauliURLProtocol.delegates.cauli_reduceAsync(record, transform: { record, delegate, completion in
            if delegate.handles(record) {
                delegate.willRequest(record) { record in
                    completion(record)
                }
            } else {
                completion(record)
            }
        }, completion: { record in
            completionHandler(record)
        })
    }

    private func didRespond(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        CauliURLProtocol.delegates.cauli_reduceAsync(record, transform: { record, delegate, completion in
            if delegate.handles(record) {
                delegate.didRespond(record) { record in
                    completion(record)
                }
            } else {
                completion(record)
            }
        }, completion: { record in
            completionHandler(record)
        })
    }

    /// A CauliURLProtocol instance holds a strong reference to its executingURLSession, which
    /// itself holds a strong reference to its delegate, the CauliURLProtocol instance.
    /// To break this retain cycle we have to call the `finishTasksAndInvalidate`.
    private func invalidateURLSession() {
        self.executingURLSession.finishTasksAndInvalidate()
    }
}
