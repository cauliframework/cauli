//
//  MemoryStorage.swift
//  cauli
//
//  Created by Pascal Stüdlein on 07.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

public class MemoryStorage: Storage {
    private var storage: [URLRequest: NetworkRecord] = [:]
    
    public init() {}
    
    public func store(_ originalRequest: URLRequest, for request: URLRequest) {
        storage[request] = StaticNetworkRecord(originalRequest: originalRequest, request: request)
    }
    
    public func store(_ response: URLResponse, for request: URLRequest) {
        storage[request]?.response = response
    }
    
    public func store(_ metrics: URLSessionTaskMetrics, for request: URLRequest) {
        storage[request]?.metrics = metrics
    }
    
    public func store(_ data: Data, for request: URLRequest) {
        storage[request]?.data = data
    }
    
    public func store(_ error: Error, for request: URLRequest) {
        storage[request]?.error = error
    }
    
    public var records: [NetworkRecord] {
        get {
            return storage.values.sorted(by: { $0.createdAt < $1.createdAt })
        }
    }
}
