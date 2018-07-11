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
    
    // create an executing URLSession in which every request is actually being performed and make sure it doesn't contain the CauliURLProtocol
    
    internal static var cauliInstances: [Weak<Cauli>] = []
    private static var existingCauliInstances: [Cauli] {
        return cauliInstances.compactMap { $0.value }
    }
    private var networkDataTask: URLSessionDataTask?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return existingCauliInstances.reduce(false, { (current, cauli) -> Bool in
            current || cauli.canInit(with: request)
        })
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.protocolClasses = sessionConfiguration.protocolClasses?.filter({ $0 != CauliURLProtocol.self })
        super.init(request: request, cachedResponse: cachedResponse, client: client)
        executingURLSession = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    }
    
    override func startLoading() {
        let networkRequest = request
        // TODO: check all cauli instances if they want to change the request
        // TODO: check all cauli instances if they want to set the response (maybe this is the same as the first todo)
        
        let dataTask: URLSessionDataTask = executingURLSession.dataTask(with: request)
        let response: URLResponse? = nil // record.response
        let error: Error? = nil // record.error
        let data: Data? = nil // record.data
        if let response = response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } else if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            dataTask.resume()
        }
        networkDataTask = dataTask
    }
    
    override func stopLoading() {
        networkDataTask?.cancel()
    }
}


extension CauliURLProtocol: URLSessionDelegate, URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        // TOOD: implement me
        
        completionHandler(.allow)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        // TOOD: implement me
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // TOOD: implement me
    }
    
    
    @available(iOS 10.0, *)
    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        // TOOD: implement me
    }
}
