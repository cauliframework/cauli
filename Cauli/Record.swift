//
//  Record.swift
//  Cauli
//
//  Created by Cornelius Horstmann on 12.07.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

public enum Result<Type> {
    case error(Error)
    case result(Type)
}

public struct Record {
    var identifier: UUID
    var originalRequest: URLRequest
    var designatedRequest: URLRequest
    var result: Result<(URLResponse, Data?)>?
}

extension Record {
    init(_ request: URLRequest) {
        identifier = UUID()
        originalRequest = request
        designatedRequest = request
        result = nil
    }
}
