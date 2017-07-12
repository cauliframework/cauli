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
    var metrics: URLSessionTaskMetrics?
    var data: Data?
    var error: Error?
}

extension StaticNetworkRecord {
    init(originalRequest: URLRequest, request: URLRequest) {
        self.originalRequest = originalRequest
        self.request = request
    }
}
