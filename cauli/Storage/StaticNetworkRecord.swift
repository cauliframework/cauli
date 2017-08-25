//
//  StaticNetworkRecord.swift
//  cauli
//
//  Created by Pascal Stüdlein on 12.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

struct StaticNetworkRecord: NetworkRecord {
    var createdAt: Date = Date()
    var originalRequest: URLRequest
    var request: URLRequest
    var response: URLResponse?
    var data: Data?
    var error: Error?
}

extension StaticNetworkRecord {
    public init(originalRequest: URLRequest, request: URLRequest) {
        self.originalRequest = originalRequest
        self.request = request
    }
}

@available(iOS 10.0, *)
struct ExtendedStaticNetworkRecord: ExtendedNetworkRecord {
    var createdAt: Date = Date()
    var originalRequest: URLRequest
    var request: URLRequest
    var response: URLResponse?
    var data: Data?
    var error: Error?
    var metrics: URLSessionTaskMetrics?
}

@available(iOS 10.0, *)
extension ExtendedStaticNetworkRecord {
    public init(originalRequest: URLRequest, request: URLRequest) {
        self.originalRequest = originalRequest
        self.request = request
    }
}
