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
        guard florets.count > 0,
            florets.reduce(request, { (result, floret) -> URLRequest? in floret.request(for: result) }) != nil else { return false }
        return true
    }
    
    func request(for request: URLRequest) -> URLRequest {
        let designatedRequest = florets.reduce(request, { (result, floret) -> URLRequest? in floret.request(for: result) }) ?? request

        storage.store(designatedRequest, originalRequest: request)
        
        return designatedRequest
    }
    
    func response(for request: URLRequest) -> URLResponse? {
        let response = florets.reduce(nil, { (response, floret) -> URLResponse? in
            if let response = response {
                return response
            }
            
            return floret.response(for: request)
        })
        
        if let response = response {
            storage.store(response, for: request)
        }
        
        return response
    }
    
    func response(for response: URLResponse, request: URLRequest) -> URLResponse {
        let responseToUse = florets.reduce(nil) { (result, floret) -> URLResponse? in
            if let response = result {
                return response
            }
            
            return floret.response(for: response)
        } ?? response
        
        storage.store(responseToUse, for: request)
        
        return responseToUse
    }
}
