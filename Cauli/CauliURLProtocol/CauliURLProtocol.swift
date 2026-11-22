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
    private static var weakDelegates: [WeakReference<CauliURLProtocolDelegate>] = []
    private static var delegates: [CauliURLProtocolDelegate] {
        let nonNilDelegates = weakDelegates.filter { $0.value != nil }
        return nonNilDelegates.compactMap { $0.value as? CauliURLProtocolDelegate }
    }

    private var record: Record
    private var authenticationChallengeProxy: CauliAuthenticationChallengeProxy?

    /// Guards the properties below, which are accessed from the client's thread (`stopLoading`)
    /// and from the threads the florets complete on.
    private let stateLock = NSLock()
    private var isStopped = false
    private var executingURLSession: URLSession?
    private var dataTask: URLSessionDataTask?
    /// The record as the florets modified it before the request, once `willRequest` finished.
    private var requestedRecord: Record?
    /// `true` once the response, or the reason the request stopped, was reported to the florets.
    private var isResponseReported = false
    /// `true` once the client was told about a redirect, as it then stops this protocol for a new one.
    private var isRedirected = false

    /// `true` once the record is no longer handled while its response is loading,
    /// e.g. because it exceeds the size allowed by the `RecordSelector`.
    /// From then on the response is passed through to the client without being recorded.
    private var isPassingThrough = false

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
        !delegates.isEmpty && handles(Record(request))
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        willRequest(record) { record in
            var record = record
            record.requestStarted = Date()
            self.stateLock.lock()
            self.requestedRecord = record
            let isStopped = self.isStopped
            self.stateLock.unlock()
            guard !isStopped else {
                // The client stopped the request while the florets were modifying it.
                self.reportStop(of: record)
                return
            }
            self.record = record
            if case .result(_)? = record.result {
                self.urlSession(didCompleteWithError: nil)
            } else if case let .error(error)? = record.result {
                self.urlSession(didCompleteWithError: error)
            } else {
                self.startDataTask(with: self.record.designatedRequest)
            }
        }
    }

    override func stopLoading() {
        stateLock.lock()
        isStopped = true
        let dataTask = self.dataTask
        let requestedRecord = isRedirected ? nil : self.requestedRecord
        stateLock.unlock()

        dataTask?.cancel()
        invalidateURLSession()
        if let requestedRecord = requestedRecord {
            // E.g. the request timed out, or the app cancelled it.
            reportStop(of: requestedRecord)
        }
    }
}

extension CauliURLProtocol: URLSessionDelegate, URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        record.result = .result(Response(response, data: nil))
        if !CauliURLProtocol.handles(record) {
            startPassingThrough()
        }
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        stateLock.lock()
        isRedirected = true
        stateLock.unlock()
        client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive receivedData: Data) {
        if isPassingThrough {
            client?.urlProtocol(self, didLoad: receivedData)
            return
        }
        try? record.append(receivedData: receivedData)
        if !CauliURLProtocol.handles(record) {
            startPassingThrough()
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        urlSession(didCompleteWithError: error)
    }

    private func urlSession(didCompleteWithError error: Error?) {
        invalidateURLSession()
        // After `stopLoading` the client must not be called anymore, e.g. for the cancellation error.
        guard !hasStopped else { return }
        if isPassingThrough {
            // The record isn't handled anymore, so there is nothing to report. The URL loading system
            // calls `stopLoading` after every request, which mustn't report this one as stopped either.
            _ = markResponseReported()
            if let error = error {
                client?.urlProtocol(self, didFailWithError: error)
            } else {
                client?.urlProtocolDidFinishLoading(self)
            }
            return
        }
        if let error = error {
            record.result = .error(error as NSError)
        }
        guard markResponseReported() else { return }

        didRespond(record) { record in
            guard !self.hasStopped else { return }
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

private extension CauliURLProtocol {
    class func handles(_ record: Record) -> Bool {
        delegates.contains { $0.handles(record) }
    }

    func willRequest(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
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

    func didRespond(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
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

    /// Reports a request the client stopped to the florets, with the error the client sees,
    /// so that e.g. the storage doesn't keep it as a request without a response.
    /// The client itself isn't called anymore.
    func reportStop(of record: Record) {
        guard markResponseReported() else { return }
        var record = record
        let clientError = task?.error as NSError?
        record.result = .error(clientError ?? NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil))
        record.responseReceived = Date()
        didRespond(record) { _ in }
    }

    /// Returns `true` only the first time, so the response is reported to the florets once.
    func markResponseReported() -> Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard !isResponseReported else { return false }
        isResponseReported = true
        return true
    }

    var hasStopped: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return isStopped
    }

    func startDataTask(with request: URLRequest) {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard !isStopped else { return }
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.protocolClasses = sessionConfiguration.protocolClasses?.filter { $0 != CauliURLProtocol.self }
        let session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
        let dataTask = session.dataTask(with: request)
        executingURLSession = session
        self.dataTask = dataTask
        dataTask.resume()
    }

    /// Stops recording the response and hands it to the client as it arrives.
    /// The response and everything buffered so far is delivered once, before any further data.
    func startPassingThrough() {
        guard !isPassingThrough, case let .result(response)? = record.result else { return }
        isPassingThrough = true
        client?.urlProtocol(self, didReceive: response.urlResponse, cacheStoragePolicy: .allowed)
        if let data = response.data {
            client?.urlProtocol(self, didLoad: data)
        }
        // The record isn't handled anymore, so there is no need to keep the buffered data.
        record.result = .result(Response(response.urlResponse, data: nil))
    }

    /// A CauliURLProtocol instance holds a strong reference to its executingURLSession, which
    /// itself holds a strong reference to its delegate, the CauliURLProtocol instance.
    /// To break this retain cycle we have to call the `finishTasksAndInvalidate`.
    func invalidateURLSession() {
        stateLock.lock()
        let executingURLSession = self.executingURLSession
        stateLock.unlock()
        executingURLSession?.finishTasksAndInvalidate()
    }
}
