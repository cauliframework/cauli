//
//  MemoryStorage.swift
//  cauli
//
//  Created by Pascal Stüdlein on 07.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

/// Stores all the information defined in the Storage protocol in the RAM.
/// It uses the StaticNetworkStruct and ExtendedStaticNetworkStruct as dataSource for those informations.
public class MemoryStorage: Storage {
    
    /// helper for remembering the order of the requests
    private var orderedRequests: [URLRequest] = []
    
    private var storage: [URLRequest: NetworkRecord] = [:]
    private let recordingLimit: Int
    
    /// Determines how many NetworkRecords should be stored in RAM
    ///
    /// - Parameter recordingLimit: number of NetworkRecords to store. By default it is Int.max
    public init(recordingLimit: Int = Int.max) {
        self.recordingLimit = recordingLimit
    }
    
    public func store(_ originalRequest: URLRequest, for request: URLRequest) {
        if orderedRequests.count >= recordingLimit {
            let requestToRemove = orderedRequests.remove(at: 0)
            storage.removeValue(forKey: requestToRemove)
        }
        
        if #available(iOS 10, *) {
            storage[request] = ExtendedStaticNetworkRecord(originalRequest: originalRequest, request: request)
        } else {
            storage[request] = StaticNetworkRecord(originalRequest: originalRequest, request: request)
        }
        
        orderedRequests.append(request)
    }
    
    public func store(_ response: URLResponse, for request: URLRequest) {
        storage[request]?.response = response
    }
    
    @available(iOS 10.0, *)
    public func store(_ metrics: URLSessionTaskMetrics, for request: URLRequest) {
        guard var storage = storage[request] as? ExtendedNetworkRecord else { return }
        storage.metrics = metrics
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
