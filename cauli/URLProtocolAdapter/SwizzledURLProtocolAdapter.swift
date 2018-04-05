//
//  SwizzledURLProtocolAdapter.swift
//  cauli
//
//  Created by Pascal Stüdlein on 07.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

public class SwizzledURLProtocolAdapter: NSObject, Adapter {
    
    internal let cauli: Cauli
    internal var urlSession: URLSession!
    internal var urlProtocols: [Int:CauliURLProtocol] = [:]
    
    required public init(cauli: Cauli) {
        self.cauli = cauli
        super.init()
        let defaultC = URLSessionConfiguration.default
        defaultC.protocolClasses = defaultC.protocolClasses?.filter({ $0 != CauliURLProtocol.self })
        self.urlSession = URLSession(configuration: defaultC, delegate: self, delegateQueue: nil)
        
        CauliURLProtocol.adapter = self
    }
    
    public var isEnabled: Bool = false
    
    public func enable() {
        guard !isEnabled else { return }
        isEnabled = true
        URLSessionConfiguration.cauliSwizzleDefaultSessionConfigurationGetter()
    }
    
    public func disable() {
        guard isEnabled else { return }
        isEnabled = false
    }
    
    func canInit(_ request: URLRequest) -> Bool {
        return isEnabled && cauli.canHandle(request)
    }
    
    func startLoading(_ request: URLRequest, urlProtocol: CauliURLProtocol) -> URLSessionDataTask {
        let networkRequest = cauli.request(for: request)
        let dataTask = urlSession.dataTask(with: networkRequest)
        
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
}

extension SwizzledURLProtocolAdapter: URLSessionDelegate, URLSessionDataDelegate {
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

// This extension performes all the swizzling logic
// to replace the `URLSessionConfiguration.default` with one, where
// the `protocolClasses` contain the `CauliURLProtocol`
extension URLSessionConfiguration {
    internal static let cauliDefaultSessionConfigurationGetterMethod = class_getClassMethod(URLSessionConfiguration.self, #selector(getter: URLSessionConfiguration.default))
    internal static let cauliSwizzledSessionConfigurationGetterMethod = class_getClassMethod(URLSessionConfiguration.self, #selector(URLSessionConfiguration.cauliDefaultSessionConfiguration))
    
    internal class func cauliDefaultSessionConfiguration() -> URLSessionConfiguration {
        let configuration = cauliDefaultSessionConfiguration() // since it is swizzled, this will call the original implementation
        let protocolClasses = configuration.protocolClasses ?? []
        configuration.protocolClasses = [CauliURLProtocol.self] + protocolClasses
        return configuration
    }
    
    internal class func cauliSwizzleDefaultSessionConfigurationGetter() {
        method_exchangeImplementations(cauliDefaultSessionConfigurationGetterMethod, cauliSwizzledSessionConfigurationGetterMethod)
    }
}
