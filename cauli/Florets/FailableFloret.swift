//
//  FailableFloret.swift
//  cauli
//
//  Created by Pascal Stüdlein on 14.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

public struct FailableFloretError: Error {}

public class FailableFloret: Floret {
    public var failInterval = 3
    private var requestCounter = 0
    
    public func request(for request: URLRequest) -> URLRequest? {
        return request
    }
    
    public func response(for request: URLRequest) -> URLResponse? {
        return nil
    }
    
    public func response(for response: URLResponse) -> URLResponse? {
        return response
    }
    
    public func error(for request: URLRequest) -> Error? {
        requestCounter += 1
        
        if requestCounter % failInterval == 0 {
            return FailableFloretError()
        }
        
        return nil
    }
    
    public func data(for data: Data?, request: URLRequest) -> Data? {
        return data
    }
    
    public func error(for error: Error, request: URLRequest) -> Error {
        return error
    }
}
