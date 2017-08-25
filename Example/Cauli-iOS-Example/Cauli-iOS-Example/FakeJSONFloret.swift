//
//  FakeJSONFloret.swift
//  TestApplication
//
//  Created by Pascal Stüdlein on 22.07.17.
//  Copyright © 2017 HTW Berlin. All rights reserved.
//

import Foundation
import Cauli

class FakeJSONFloret: Floret {
    private let fakeJson = "{ \"status\": { \"code\": 234, \"message\": \"Fake json response\" } }".data(using: .utf8)
    private func canHandle(request: URLRequest) -> Bool {
        guard let headerFields = request.allHTTPHeaderFields,
            headerFields.contains(where: { $0 == "Accept" && $1 == "application/json" }) else { return false }
        
        return true
    }
    func request(for request: URLRequest) -> URLRequest? {
        return canHandle(request: request) ? request : nil
    }
    
    func response(for response: URLResponse) -> URLResponse? {
        return nil
    }
    
    func data(for data: Data?, request: URLRequest) -> Data? {
        return data == nil && canHandle(request: request) ? fakeJson : nil
    }
    
    func error(for request: URLRequest) -> Error? {
        return nil
    }
    
    func response(for request: URLRequest) -> URLResponse? {
        guard canHandle(request: request), let url = request.url else { return nil }
        return HTTPURLResponse(url: url, statusCode: 234, httpVersion: nil, headerFields: nil)
    }
}
