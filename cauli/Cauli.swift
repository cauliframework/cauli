//
//  Cauli.swift
//  cauli
//
//  Created by Pascal Stüdlein on 07.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

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
    
    struct MockedResponse {
        let data: Data
        let response: URLResponse
        let error: Error?
    }
    
    // fragen: resposne for request -> response dann nochmals alles itereiren vom response?
    func response(for request: URLRequest) -> MockedResponse? {
        guard let response = florets.reduce(nil, { (response, floret) -> URLResponse? in
            if let response = response {
                return response
            }
            
            return floret.response(for: request)
        }) else { return nil }
        
        let data = "YEAH".data(using: .utf8)!
        return MockedResponse(data: data, response: response, error: nil)
    }
    
    func response(for response: URLResponse, request: URLRequest) -> URLResponse {
        let designatedResponse = florets.reduce(response, { $1.response(for: $0) })
        
        storage.store(designatedResponse, for: request)
        
        return designatedResponse
    }
}
