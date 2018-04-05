//
//  Floret.swift
//  cauli
//
//  Created by Pascal Stüdlein on 07.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

/// In other words a floret is a plugin.
/// This protocols defines the methods a floret has to implement.
public protocol Floret {
    
    /// Inspects and optionally modifies a request
    ///
    /// - Parameter request: URLRequest to process
    /// - Returns: returns nil if floret is not interested in processing this request.
    ///        Otherwise returns the original or modified request.
    ///        Defaut implementation returns the original request.
    func request(for request: URLRequest) -> URLRequest?
    
    /// Can be used as shortcut for returning an URLResponse for a specific URLRequest.
    ///
    /// - Parameter request: URLRequest to process
    /// - Returns: designated URLResponse for the processed request
    ///        Defaut implementation returns nil.
    func response(for request: URLRequest) -> URLResponse?
    
    /// Inspects and optionally modifies a response
    ///
    /// - Parameter response: URLResponse to process
    /// - Returns: returns nil if floret is not interested in processing this response. 
    ///        Otherwise returns the original or modified response.
    ///        Should not return nil if this floret is returning a request in request(for request: URLRequest).
    ///        Defaut implementation returns the original request.
    func response(for response: URLResponse) -> URLResponse?
    
    /// Inspects and optionally modifies data of a request
    ///
    /// - Parameters:
    ///   - data: Data to process
    ///   - request: The request which the data are for
    /// - Returns: returns nil if there are no data for this request.
    ///        Otherwise returns the original or modified data.
    ///        Defaut implementation returns nil.
    func data(for data: Data?, request: URLRequest) -> Data?
    
    /// Can be used as shortcut for returning a Error for a specific URLRequest.
    ///
    /// - Parameter request: URLRequest to process
    /// - Returns: designated Error for the processed request
    ///        Defaut implementation returns nil.
    func error(for request: URLRequest) -> Error?
    
    /// Can be used for inspecting or modifing a specific error
    ///
    /// - Parameters:
    ///   - error: occured error
    ///   - request: underlaying request
    /// - Returns: designated error
    ///        Defaut implementation returns the original error.
    func error(for error: Error, request: URLRequest) -> Error
}

public extension Floret {
    
    func request(for request: URLRequest) -> URLRequest? {
        return request
    }
    
    func response(for request: URLRequest) -> URLResponse? {
        return nil
    }
    
    func response(for response: URLResponse) -> URLResponse? {
        return response
    }
    
    func data(for data: Data?, request: URLRequest) -> Data? {
        return data
    }
    
    func error(for request: URLRequest) -> Error? {
        return nil
    }
    
    func error(for error: Error, request: URLRequest) -> Error {
        return error;
    }
}
