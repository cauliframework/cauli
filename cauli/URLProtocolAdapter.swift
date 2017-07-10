//
//  URLProtocolAdapter.swift
//  cauli
//
//  Created by Pascal Stüdlein on 07.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

class URLProtocolAdapter:  NSObject, Adapter {
    weak var cauli: Cauli?
    private(set) var urlSession: URLSession!
    fileprivate var urlProtocols: [Int:CauliURLProtocol] = [:]
    
    override init() {
        super.init()
        self.urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
    }
    
    func configure() {
        CauliURLProtocol.adapter = self
    }
    
    func canInit(_ request: URLRequest) -> Bool {
        guard let cauli = cauli else { return false }
        return cauli.canHandle(request)
    }
    
    func startLoading(_ request: URLRequest, urlProtocol:CauliURLProtocol) -> URLSessionDataTask {
        guard let cauli = cauli else { fatalError("") }
        
        let networkRequest = cauli.request(for: request)
        let dataTask = urlSession.dataTask(with: networkRequest)
        
        if let mockedResponse = cauli.response(for: networkRequest) {
            if let error = mockedResponse.error {
                urlProtocol.client?.urlProtocol(urlProtocol, didFailWithError: error)
            }
            
            urlProtocol.client?.urlProtocol(urlProtocol, didLoad: mockedResponse.data)
            urlProtocol.client?.urlProtocol(urlProtocol, didReceive: mockedResponse.response, cacheStoragePolicy: .allowed)
            urlProtocol.client?.urlProtocolDidFinishLoading(urlProtocol)
        } else {
            urlProtocols[dataTask.taskIdentifier] = urlProtocol
            dataTask.resume()
        }
        
        return dataTask
    }
}

extension URLProtocolAdapter: URLSessionDelegate, URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let urlProtocol = urlProtocols[dataTask.taskIdentifier] else { return completionHandler(.cancel) }

        if let cauli = cauli, let originalRequest = dataTask.originalRequest {
            let newResponse = cauli.response(for: response, request: originalRequest)
            urlProtocol.client?.urlProtocol(urlProtocol, didReceive: newResponse, cacheStoragePolicy: .allowed)
        }
        
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let urlProtocol = urlProtocols[dataTask.taskIdentifier] else { return }
        
        urlProtocol.client?.urlProtocol(urlProtocol, didLoad: data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let urlProtocol = urlProtocols[task.taskIdentifier] else { return }
        
        if let error = error {
            urlProtocol.client?.urlProtocol(urlProtocol, didFailWithError: error)
        }
        
        urlProtocol.client?.urlProtocolDidFinishLoading(urlProtocol)
        urlProtocols.removeValue(forKey: task.taskIdentifier)
    }
}


extension URLProtocolAdapter {
    public class func register(for configuration: URLSessionConfiguration) {
        let protocolClasses = configuration.protocolClasses ?? []
        configuration.protocolClasses = ([CauliURLProtocol.self] + protocolClasses)
    }
    
    public class func swizzle() {
        let defaultSessionConfiguration = class_getClassMethod(URLSessionConfiguration.self, #selector(getter: URLSessionConfiguration.default))
        let mockingjayDefaultSessionConfiguration = class_getClassMethod(URLSessionConfiguration.self, #selector(URLSessionConfiguration.cauliDefaultSessionConfiguration))
        method_exchangeImplementations(defaultSessionConfiguration, mockingjayDefaultSessionConfiguration)
        
    }
}
