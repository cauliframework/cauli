//
//  Storage.swift
//  cauli
//
//  Created by Pascal Stüdlein on 07.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

protocol Storage {
    func store(_ request: URLRequest, originalRequest: URLRequest)
    func store(_ response: URLResponse, for request: URLRequest)
    func store(_ metrics: URLSessionTaskMetrics, for request: URLRequest)
    func store(_ data: Data, for request: URLRequest)
}
