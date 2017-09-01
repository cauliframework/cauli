//
//  Storage.swift
//  cauli
//
//  Created by Pascal Stüdlein on 07.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

/// Defines the methods a Storage must implement
///  to store informations about a URLRequest
public protocol Storage {
    func store(_ originalRequest: URLRequest, for request: URLRequest)
    func store(_ response: URLResponse, for request: URLRequest)
    func store(_ data: Data, for request: URLRequest)
    func store(_ error: Error, for request: URLRequest)
    @available(iOS 10.0, *)
    func store(_ metrics: URLSessionTaskMetrics, for request: URLRequest)
    
    var records: [NetworkRecord] { get }
}
