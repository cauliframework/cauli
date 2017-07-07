//
//  Floret.swift
//  cauli
//
//  Created by Pascal Stüdlein on 07.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

protocol Floret {
    func request(for request: URLRequest)
    func response(for request: URLRequest)
    func response(for response: URLResponse)
    func collected(metrics: URLSessionTaskMetrics, for request:URLRequest)
}
