//
//  Cauli.swift
//  cauli
//
//  Created by Pascal Stüdlein on 07.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

struct MockedResponse {
    let data: Data
    let response: URLResponse
}

public class Cauli {
    // todo florets initalizer to be static
    public var florets: [Floret] = []
    // todo request cache useless
    //    var requestCache: [URLRequest:URLRequest] = [:]
    let storage: Storage
    
    public init(storage: Storage = PrintStorage()) {
        self.storage = storage
    }
    
    func canHandle(_ request: URLRequest) -> Bool {
        guard florets.count > 0 else { return false }
        return florets.contains(where: { $0.request(for: request) != nil })
    }
    
    func request(for request: URLRequest) -> URLRequest {
        var designatedRequest = florets.reduce(request, {
            return $1.request(for: $0) ?? $0
        })
        designatedRequest.addValue(String(Date().timeIntervalSince1970), forHTTPHeaderField: "X-Cauli")
        
        storage.store(request, for: designatedRequest)
        
        return designatedRequest
    }
    
    // fragen: resposne for request -> response dann nochmals alles itereiren vom response?
    // todo rethink. error should be extra case
    func response(for request: URLRequest) -> MockedResponse? {
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
    
    func error(for error: Error, request: URLRequest) -> Error {
        // todo florets?
        storage.store(error, for: request)
        return error
    }
    
    func error(for request: URLRequest) -> Error? {
        guard let error = florets.reduce(nil, { (error, floret) -> Error? in
            if let error = error {
                return error
            }
            
            return floret.error(for: request)
        }) else { return nil }
        
        storage.store(error, for: request)
        
        return error
    }
    
    func response(for response: URLResponse, request: URLRequest) -> URLResponse {
        let designatedResponse = florets.reduce(response, { $1.response(for: $0) ?? response })
        
        storage.store(designatedResponse, for: request)
        
        return designatedResponse
    }
    
    func data(for data: Data, request: URLRequest) -> Data {
        let designatedData = florets.reduce(data, {
            return $1.data(for: $0, request: request) ?? $0
        })
        
        storage.store(designatedData, for: request)
        return designatedData
    }
    
    @available(iOS 10.0, *)
    func collected(_ metrics: URLSessionTaskMetrics, for request: URLRequest) {
        storage.store(metrics, for: request)
    }
}
