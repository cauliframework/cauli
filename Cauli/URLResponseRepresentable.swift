//
//  URLResponseRepresentable.swift
//  Cauli
//
//  Created by Pascal Stüdlein on 26.08.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

enum URLResponseRepresentable {
    case urlResponse(URLResponse)
    case httpURLResponse(HTTPURLResponse)
    
    public var urlResponse: URLResponse {
        switch self {
        case .urlResponse(let urlResponse): return urlResponse
        case .httpURLResponse(let httpURLResponse): return httpURLResponse as URLResponse
        }
    }
    
    init(_ urlResponse: URLResponse) {
        if let urlResponse = urlResponse as? HTTPURLResponse {
            self = .httpURLResponse(urlResponse)
        } else {
            self = .urlResponse(urlResponse)
        }
    }
}

extension URLResponseRepresentable: Codable {
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let internalHTTPURLResponse = try? container.decode(InternalHTTPURLResponse.self),
            let httpURLResponse = HTTPURLResponse(internalHTTPURLResponse: internalHTTPURLResponse) {
            self = .httpURLResponse(httpURLResponse)
        } else if let internalURLResponse = try? container.decode(InternalURLResponse.self) {
            self = .urlResponse(URLResponse(internalURLResponse: internalURLResponse))
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "🤷‍♂️")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .httpURLResponse(let httpURLResponse):
            try container.encode(httpURLResponse.internalHTTPURLResponse)
        case .urlResponse(let urlResponse):
            try container.encode(urlResponse.internalURLResponse)
        }
    }

}

struct InternalURLResponse: Codable {
    let url: URL
    let mimeType: String?
    let expectedContentLength: Int
    let textEncodingName: String?
}

struct InternalHTTPURLResponse: Codable {
    let url: URL
    let statusCode: Int
    let httpVersion: String?
    let headerFields: [String : String]?
}

extension URLResponse {
    var internalURLResponse: InternalURLResponse {
        guard let url = url else { fatalError() }
        return InternalURLResponse(url: url, mimeType: mimeType, expectedContentLength: Int(expectedContentLength), textEncodingName: textEncodingName)
    }
    
    convenience init(internalURLResponse: InternalURLResponse) {
        self.init(url: internalURLResponse.url, mimeType: internalURLResponse.mimeType, expectedContentLength: internalURLResponse.expectedContentLength, textEncodingName: internalURLResponse.textEncodingName)
    }
}

extension HTTPURLResponse {
    var internalHTTPURLResponse: InternalHTTPURLResponse {
        guard let url = url else { fatalError() }
        
        let compatibleHeaderFields: [String: String] = allHeaderFields.reduce([:]) { (result, keyValuePair: (key: AnyHashable, value: Any)) -> [String: String] in
            
            var newResult = result
            if let keyString = keyValuePair.key as? String, let valueString = keyValuePair.value as? String { // improve
                newResult[keyString] = valueString
            }
            
            return newResult
        }

        return InternalHTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: compatibleHeaderFields)
    }
    
    convenience init?(internalHTTPURLResponse: InternalHTTPURLResponse) {
        self.init(url: internalHTTPURLResponse.url, statusCode: internalHTTPURLResponse.statusCode, httpVersion: internalHTTPURLResponse.httpVersion, headerFields: internalHTTPURLResponse.headerFields)
    }
}
