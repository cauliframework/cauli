//
//  PrintStorage.swift
//  cauli
//
//  Created by Pascal Stüdlein on 07.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

class PrintStorage: Storage {
    func store(_ request: URLRequest, originalRequest: URLRequest) {
//        print("store designated request for originalRequest")
        print("store designated request \(request) for originalRequest \(originalRequest)")
    }
    
    func store(_ response: URLResponse, for request: URLRequest) {
//        print("store response for request")
        print("store response \(response) for request \(request)")
    }
    
    func store(_ metrics: URLSessionTaskMetrics, for request: URLRequest) {
        print("store metrics for request")
//        print("store metrics \(metrics) for request \(request)")
    }
    
    func store(_ data: Data, for request: URLRequest) {
        print("store data for request")
//        print("store data \(data) for request \(request)")
    }
    
    func store(_ error: Error, for request: URLRequest) {
        print("error")
    }
    
    var records: [NetworkRecord] {
        return []
    }
}
