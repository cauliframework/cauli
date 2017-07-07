//
//  Cauli.swift
//  cauli
//
//  Created by Pascal Stüdlein on 07.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

class Cauli {   
    var florets: [Floret] = []
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
        return florets.reduce(false, { $0 || $1.request(for: request) != nil })
    }
    
    func request(for request: URLRequest) -> URLRequest {
        let networkRequest = florets.reduce(nil) { (result, floret) -> URLRequest? in
            if let request = result {
                return request
            }
            
            return floret.request(for: request)
        } ?? request

        storage.store(networkRequest, originalRequest: request)
        return networkRequest
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
