//
//  Record.swift
//  Cauli
//
//  Created by Cornelius Horstmann on 12.07.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

public struct Record: Codable {
    public var identifier: UUID
    public var originalRequest: URLRequest
    public var designatedRequest: URLRequest
    public var result: Result<Response>
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
        self.result = .result(Response(result.urlResponse, data: result.data))
    }
}
