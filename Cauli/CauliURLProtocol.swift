//
//  CauliURLProtocol.swift
//  Cauli
//
//  Created by Cornelius Horstmann on 11.07.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

internal class CauliURLProtocol: URLProtocol {
    
    private var executingURLSession: URLSession!
    
    private static var delegates: [CauliURLProtocolDelegate] = []
    
    private var record: Record
    private var dataTask: URLSessionDataTask?
    
    internal static func add(delegate: CauliURLProtocolDelegate) {
        delegates.append(delegate)
    }
    
    internal static func remove(delegate: CauliURLProtocolDelegate) {
        delegates = delegates.filter { $0 !== delegate}
    }
    
    override init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        record = Record(request)
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.protocolClasses = sessionConfiguration.protocolClasses?.filter({ $0 != CauliURLProtocol.self })
        super.init(request: request, cachedResponse: cachedResponse, client: client)
        executingURLSession = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    }
}

// Overriding URLProtocol functions
extension CauliURLProtocol {
    
    override class func canInit(with task: URLSessionTask) -> Bool {
        return task is URLSessionDataTask && delegates.count > 0
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        return delegates.count > 0
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        record = CauliURLProtocol.delegates.reduce(record) { (record, delegate) in
            delegate.willRequest(record)
        }
        
        if case let .result(response, data) = record.result {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } else if case let .error(error) = record.result {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            dataTask = executingURLSession.dataTask(with: request)
            dataTask?.resume()
        }
    }
    
    override func stopLoading() {
        dataTask?.cancel()
    }
}

extension CauliURLProtocol: URLSessionDelegate, URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        record.result = .result((response, nil))
        completionHandler(.allow)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive receivedData: Data) {
        try? record.append(receivedData)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            record.result = .error(error)
        }
        record = CauliURLProtocol.delegates.reduce(record) { (record, delegate) in
            delegate.didRespond(record)
        }
        
        switch record.result {
        case .result((let response, let data)):
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        case .error(let error):
            client?.urlProtocol(self, didFailWithError: error)
        case .none:
            client?.urlProtocol(self, didFailWithError: NSError(domain: "FIXME", code: 0, userInfo: [:]))
        }
    }
    
    @available(iOS 10.0, *)
    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        // possibly add the metrics to the record in the future
    }
}
