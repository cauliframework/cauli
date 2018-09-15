//
//  Result.swift
//  Cauli
//
//  Created by Pascal Stüdlein on 15.09.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

public enum Result<Type: Codable> {
    case none
    case error(NSError)
    case result(Type)
}

extension Result: Codable {

    private enum CodingKeys: CodingKey {
        case none
        case error
        case result
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let decodedType = try? container.decode(Type.self) {
            self = .result(decodedType)
        } else if let internalError = try? container.decode(InternalError.self) {
            self = .error(NSError(domain: internalError.domain, code: internalError.code, userInfo: internalError.userInfo))
        } else {
            self = .none
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .none:
            try container.encodeNil()
        case .error(let error):

            try container.encode(InternalError(domain: error.domain, code: error.code, userInfo: error.compatibleUserInfo))
        case .result(let type):
            try container.encode(type)
        }
    }

}
