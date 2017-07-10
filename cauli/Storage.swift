//
//  Storage.swift
//  cauli
//
//  Created by Pascal Stüdlein on 07.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

struct NetworkRecord {
    let createdAt: Date = Date()
    var originalRequest: URLRequest
    var request: URLRequest
    var response: URLResponse?
    var metrics: URLSessionTaskMetrics?
    var data: Data?
    var error: Error?
}

extension NetworkRecord {
    init(originalRequest: URLRequest, request: URLRequest) {
        self.originalRequest = originalRequest
        self.request = request
    }
}

protocol Storage {
    func store(_ request: URLRequest, originalRequest: URLRequest)
    func store(_ response: URLResponse, for request: URLRequest)
    func store(_ metrics: URLSessionTaskMetrics, for request: URLRequest)
    func store(_ data: Data, for request: URLRequest)
    func store(_ error: Error, for request: URLRequest)
    
    var records: [NetworkRecord] { get }
}
