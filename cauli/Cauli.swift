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

class Cauli {
    // todo florets initalizer to be static
    var florets: [Floret] = []
    // todo request cache useless
//    var requestCache: [URLRequest:URLRequest] = [:]
    private var adapter: Adapter
    let storage: Storage

    init(adapter: Adapter = URLProtocolAdapter(), storage: Storage = PrintStorage()) {
        self.adapter = adapter
        self.storage = storage
        
        self.adapter.cauli = self
        self.adapter.configure()
    }
    
    func canHandle(_ request: URLRequest) -> Bool {
        guard florets.count > 0 else { return false }
        
        var canHandle = false
        for floret in florets {
            if floret.request(for: request) != nil {
                canHandle = true
                break
            }
        }
        
        return canHandle
    }
    
    func request(for request: URLRequest) -> URLRequest {
        let designatedRequest = florets.reduce(request, { $1.request(for: $0) ?? request })
        
        storage.store(designatedRequest, originalRequest: request)
        
        return designatedRequest
    }
    
    // fragen: resposne for request -> response dann nochmals alles itereiren vom response?
    // todo rethink. error should be extra case
    func response(for request: URLRequest) -> MockedResponse? {
        guard let response = florets.reduce(nil, { (response, floret) -> URLResponse? in
            if let response = response {
                return response
            }
            
            return floret.response(for: request)
        }) else { return nil }
        
        let data = "YEAH".data(using: .utf8)!
        
        storage.store(data, for: request)
        storage.store(response, for: request)
        
        return MockedResponse(data: data, response: response)
    }
    
    func error(for request: URLRequest) -> Error? {
        guard let error = florets.reduce(nil, { (error, floret) -> Error? in
            if let error = error {
                return error
            }
            
            return floret.error(for: request)
        }) else { return nil }
        
        //ggf store
        
        return error
    }
    
    func response(for response: URLResponse, request: URLRequest) -> URLResponse {
        let designatedResponse = florets.reduce(response, { $1.response(for: $0) ?? response })
        
        storage.store(designatedResponse, for: request)
        
        return designatedResponse
    }
    
    func didLoad(_ data: Data, for request: URLRequest) {
        storage.store(data, for: request)
    }
    
    func collected(_ metrics: URLSessionTaskMetrics, for request: URLRequest) {
        storage.store(metrics, for: request)
    }
}
