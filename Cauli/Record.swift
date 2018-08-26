//
//  Record.swift
//  Cauli
//
//  Created by Cornelius Horstmann on 12.07.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

public enum Result<Type> {
    case none
    case error(Error)
    case result(Type)
}

public struct CauliResponse {
    let response: URLResponse
    let data: Data?
}

public struct Record {
    public var identifier: UUID
    public var originalRequest: URLRequest
    public var designatedRequest: URLRequest
    public var result: Result<CauliResponse>
}

extension Record {
    init(_ request: URLRequest) {
        identifier = UUID()
        originalRequest = request
        designatedRequest = request
        result = .none
    }
}

extension Record {
    mutating func append(_ receivedData: Data) throws {
        guard case let .result(result) = result else {
            // TODO: use a proper error here
            throw NSError(domain: "FIXME", code: 0, userInfo: [:])
        }
        var currentData = result.data ?? Data()
        currentData.append(receivedData)
        self.result = .result(CauliResponse(response: result.response, data: result.data))
    }
}
