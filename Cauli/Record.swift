//
//  Record.swift
//  Cauli
//
//  Created by Cornelius Horstmann on 12.07.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

//public enum Result<Type: Codable> {
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

public struct CauliResponse: Codable {
    public let data: Data?
    public var response: URLResponse {
        get {
            switch urlResponseRepresentable {
            case .httpURLResponse(let httpURLResponse):
                return httpURLResponse
            case .urlResponse(let response):
                return response
            }
        }
        set {
            if let httpRespnose = newValue as? HTTPURLResponse {
                urlResponseRepresentable = .httpURLResponse(httpRespnose)
            } else {
                urlResponseRepresentable = .urlResponse(newValue)
            }
        }
    }
    
    init(response: URLResponse, data: Data?) {
        self.data = data
        if let httpRespnose = response as? HTTPURLResponse {
            urlResponseRepresentable = .httpURLResponse(httpRespnose)
        } else {
            urlResponseRepresentable = .urlResponse(response)
        }
    }
    
    private var urlResponseRepresentable: URLResponseRepresentable
}

public struct Record: Codable {
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
