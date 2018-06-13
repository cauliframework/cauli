//
//  Cauli.swift
//  cauli
//
//  Created by Pascal Stüdlein on 07.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

/// DataStructure used by a Cauli instance to bind Data to a URLResponse.
struct MockedResponse {
    let data: Data
    let response: URLResponse
}

/// Cauli holds references to n Florets and one Storage.
/// An Adapter is tunneling the network traffic through an instance of Cauli.
/// It offers Florets the possibility to modify the traffic.
/// In the end the (modified) traffic is stored in a Storage instance.
public class Cauli {
    public var florets: [Floret] = []
    public let storage: Storage
    public private(set) var adapter: Adapter!
    
    public init(storage: Storage = PrintStorage(), adapter: Adapter = SwizzledURLProtocolAdapter()) {
        self.storage = storage
        self.adapter = adapter
        self.adapter.cauli = self
    }
    
    public func enable() {
        adapter.enable()
    }
    
    public func disable() {
        adapter.disable()
    }
    
    internal func canHandle(_ request: URLRequest) -> Bool {
        guard florets.count > 0 else { return false }
        return florets.contains(where: { $0.request(for: request) != nil })
    }
    
    internal func request(for request: URLRequest) -> URLRequest {
        var designatedRequest = florets.reduce(request, {
            return $1.request(for: $0) ?? $0
        })
        designatedRequest.addValue(String(Date().timeIntervalSince1970), forHTTPHeaderField: "X-Cauli")
        
        storage.store(request, for: designatedRequest)
        
        return designatedRequest
    }
    
    internal func response(for request: URLRequest) -> MockedResponse? {
        let result = florets.reduce(nil) { (result, floret) -> (response: URLResponse, data: Data)? in
            if let result = result {
                return result
            }
            
            guard let r = floret.response(for: request) else { return nil }
            return (r, floret.data(for: nil, request: request) ?? Data())
        }
        
        guard let response = result?.response, let data = result?.data else { return nil }
        
        storage.store(data, for: request)
        storage.store(response, for: request)
        return MockedResponse(data: data, response: response)
    }
    
    internal func error(for error: Error, request: URLRequest) -> Error {
        let designatedError = florets.reduce(error, {
            return $1.error(for: $0, request: request)
        })
        
        storage.store(designatedError, for: request)
        return designatedError
    }
    
    internal func error(for request: URLRequest) -> Error? {
        guard let error = florets.reduce(nil, { (error, floret) -> Error? in
            if let error = error {
                return error
            }
            
            return floret.error(for: request)
        }) else { return nil }
        
        storage.store(error, for: request)
        
        return error
    }
    
    internal func response(for response: URLResponse, request: URLRequest) -> URLResponse {
        let designatedResponse = florets.reduce(response, { $1.response(for: $0) ?? response })
        
        storage.store(designatedResponse, for: request)
        
        return designatedResponse
    }
    
    internal func data(for data: Data, request: URLRequest) -> Data {
        let designatedData = florets.reduce(data, {
            return $1.data(for: $0, request: request) ?? $0
        })
        
        storage.store(designatedData, for: request)
        return designatedData
    }
    
    @available(iOS 10.0, *)
    internal func collected(_ metrics: URLSessionTaskMetrics, for request: URLRequest) {
        storage.store(metrics, for: request)
    }
}
