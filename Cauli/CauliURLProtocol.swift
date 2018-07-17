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
    
    private var record: Record?
    private var dataTask: URLSessionDataTask?
    
    internal static func add(delegate: CauliURLProtocolDelegate) {
        delegates.append(delegate)
    }
    
    internal static func remove(delegate: CauliURLProtocolDelegate) {
        delegates = delegates.filter { $0 !== delegate}
    }
    
    override init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.protocolClasses = sessionConfiguration.protocolClasses?.filter({ $0 != CauliURLProtocol.self })
        super.init(request: request, cachedResponse: cachedResponse, client: client)
        executingURLSession = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    }
}

// Overriding URLProtocol functions
extension CauliURLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        for delegate in delegates where delegate.canHandle(request) {
            return true
        }
        return false
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        var record = Record(request)
        record = CauliURLProtocol.delegates.reduce(record) { (record, delegate) in
            delegate.willRequest(record)
        }
        
        let dataTask: URLSessionDataTask = executingURLSession.dataTask(with: request)
        if let result = record.result, case let .result(response, data) = result {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } else if let result = record.result, case let .error(error) = result {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            dataTask.resume()
        }
        self.record = record
        self.dataTask = dataTask
    }
    
    override func stopLoading() {
        dataTask?.cancel()
    }
}

extension CauliURLProtocol: URLSessionDelegate, URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        record?.result = .result((response, nil))
        completionHandler(.allow)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let result = record?.result, case let .result(response, _) = result {
            record?.result = .result((response, data))
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            record?.result = .error(error)
        }
    }
    
    @available(iOS 10.0, *)
    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        // possibly add the metrics to the record in the future
    }
}
