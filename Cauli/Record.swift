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
    case error(Error)
    case result(Type)
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
