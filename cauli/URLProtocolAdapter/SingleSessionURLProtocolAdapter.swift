//
//  SingleSessionURLProtocolAdapter.swift
//  cauli
//
//  Created by Cornelius Horstmann on 03.05.18.
//  Copyright © 2018 TBO Interactive GmbH & CO KG. All rights reserved.
//

import Foundation

public class SingleSessionURLProtocolAdapter: NSObject {
    
    public var urlSession: URLSession!
    public var isEnabled: Bool = false
    
    internal let cauli: Cauli
    internal var executingURLSession: URLSession!
    internal var urlProtocols: [Int:CauliURLProtocol] = [:]
    
    required public init(cauli: Cauli, sessionConfiguration originalSessionConfiguration: URLSessionConfiguration?) {
        self.cauli = cauli
        super.init()
        let sessionConfiguration = SingleSessionURLProtocolAdapter.sessionConfiguration(with: originalSessionConfiguration)
        self.urlSession = URLSession(configuration: sessionConfiguration)
        self.executingURLSession = URLSession(configuration: originalSessionConfiguration ?? URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        CauliURLProtocol.adapter = self
    }
    
    required convenience public init(cauli: Cauli) {
        self.init(cauli: cauli, sessionConfiguration: nil)
    }
    
    private static func sessionConfiguration(with sessionConfiguration: URLSessionConfiguration?) -> URLSessionConfiguration {
        let sessionConfiguration = sessionConfiguration ?? URLSessionConfiguration.default
        sessionConfiguration.protocolClasses = [CauliURLProtocol.self] + (sessionConfiguration.protocolClasses ?? [])
        return sessionConfiguration
    }
}

extension SingleSessionURLProtocolAdapter: URLProtocolAdapter {
    
    func canInit(_ request: URLRequest) -> Bool {
        return isEnabled && cauli.canHandle(request)
    }
    
    func startLoading(_ request: URLRequest, urlProtocol: CauliURLProtocol) -> URLSessionDataTask {
        let networkRequest = cauli.request(for: request)
        let dataTask = executingURLSession.dataTask(with: networkRequest)
        
        if let mockedResponse = cauli.response(for: networkRequest) {
            urlProtocol.client?.urlProtocol(urlProtocol, didReceive: mockedResponse.response, cacheStoragePolicy: .allowed)
            urlProtocol.client?.urlProtocol(urlProtocol, didLoad: mockedResponse.data)
            urlProtocol.client?.urlProtocolDidFinishLoading(urlProtocol)
        } else if let error = cauli.error(for: networkRequest) {
            urlProtocol.client?.urlProtocol(urlProtocol, didFailWithError: error)
        } else {
            urlProtocols[dataTask.taskIdentifier] = urlProtocol
            dataTask.resume()
        }
        
        return dataTask
    }
    
    public func enable() {
        isEnabled = true
    }
    
    public func disable() {
        isEnabled = false
    }
}

extension SingleSessionURLProtocolAdapter: URLSessionDelegate, URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let urlProtocol = urlProtocols[dataTask.taskIdentifier] else { return completionHandler(.cancel) }
        
        if let originalRequest = dataTask.originalRequest {
            let newResponse = cauli.response(for: response, request: originalRequest)
            urlProtocol.client?.urlProtocol(urlProtocol, didReceive: newResponse, cacheStoragePolicy: .allowed)
        }
        
        completionHandler(.allow)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let urlProtocol = urlProtocols[dataTask.taskIdentifier],
            let originalRequest = dataTask.originalRequest else { return }
        
        urlProtocol.client?.urlProtocol(urlProtocol, didLoad: cauli.data(for: data, request: originalRequest))
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let urlProtocol = urlProtocols[task.taskIdentifier] else { return }
        
        if let error = error, let originalRequest = task.originalRequest {
            let designatedError = cauli.error(for: error, request: originalRequest)
            urlProtocol.client?.urlProtocol(urlProtocol, didFailWithError: designatedError)
        } else {
            urlProtocol.client?.urlProtocolDidFinishLoading(urlProtocol)
        }
        
        urlProtocols.removeValue(forKey: task.taskIdentifier)
    }

    
    @available(iOS 10.0, *)
    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        guard let originalRequest = task.originalRequest else { return }
        cauli.collected(metrics, for: originalRequest)
    }
}
