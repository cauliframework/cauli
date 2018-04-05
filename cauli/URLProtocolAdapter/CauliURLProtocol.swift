//
//  CauliURLProtocol.swift
//  cauli
//
//  Created by Pascal Stüdlein on 07.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

class CauliURLProtocol: URLProtocol {
    
    static var adapter: SwizzledURLProtocolAdapter?
    var networkDataTask: URLSessionDataTask?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return adapter?.canInit(request) ?? false
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        networkDataTask = CauliURLProtocol.adapter?.startLoading(request, urlProtocol: self)
    }
    
    override func stopLoading() {
        networkDataTask?.cancel()
    }
}
