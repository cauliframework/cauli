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
    ///        Otherwise returns the original or modified request
    func request(for request: URLRequest) -> URLRequest?
    
    /// Can be used as shortcut for returning an URLResponse for a specific URLRequest.
    ///
    /// - Parameter request: URLRequest to process
    /// - Returns: designated URLResponse for the processed request
    func response(for request: URLRequest) -> URLResponse?
    
    /// Inspects and optionally modifies a response
    ///
    /// - Parameter response: URLResponse to process
    /// - Returns: returns nil if floret is not interested in processing this response. 
    ///     Otherwise returns the original or modified response.
    ///     Should not return nil if this floret is returning a request in request(for request: URLRequest).
    func response(for response: URLResponse) -> URLResponse?
    
    /// Inspects and optionally modifies data of a request
    ///
    /// - Parameters:
    ///   - data: Data to process
    ///   - request: The request which the data are for
    /// - Returns: returns nil if there are no data for this request.
    ///     Otherwise returns the original or modified data.
    func data(for data: Data?, request: URLRequest) -> Data?
    
    /// Can be used as shortcut for returning a Error for a specific URLRequest.
    ///
    /// - Parameter request: URLRequest to process
    /// - Returns: designated Error for the processed request
    func error(for request: URLRequest) -> Error?
}
