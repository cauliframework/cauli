//
//  Floret.swift
//  cauli
//
//  Created by Pascal Stüdlein on 07.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

public protocol Floret {
    func request(for request: URLRequest) -> URLRequest?
    func response(for request: URLRequest) -> URLResponse?
    func response(for response: URLResponse) -> URLResponse?
    func error(for request: URLRequest) -> Error?
}
