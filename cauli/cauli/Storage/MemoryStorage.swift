//
//  MemoryStorage.swift
//  cauli
//
//  Created by Pascal Stüdlein on 07.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

class MemoryStorage: Storage {
    private var storage: [URLRequest: NetworkRecord] = [:]

    func store(_ request: URLRequest, originalRequest: URLRequest) {
        storage[request] = NetworkRecord(originalRequest: originalRequest, request: request)
    }
    
    func store(_ response: URLResponse, for request: URLRequest) {
        storage[request]?.response = response
    }

    func store(_ metrics: URLSessionTaskMetrics, for request: URLRequest) {
        storage[request]?.metrics = metrics
    }
    
    func store(_ data: Data, for request: URLRequest) {
        storage[request]?.data = data
    }
    
    func store(_ error: Error, for request: URLRequest) {
        storage[request]?.error = error
    }
    
    var records: [NetworkRecord] {
        get {
            return storage.values.sorted(by: { $0.createdAt < $1.createdAt })
        }
    }
}
