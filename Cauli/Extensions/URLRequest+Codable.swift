//
//  Copyright (c) 2018 cauli.works
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

extension URLRequest: Codable {

    enum CodingKeys: CodingKey {
        case url
        case cachePolicy
        case timeoutInterval
        case mainDocumentURL
        case allowsCelluarAccess
        case httpMethod
        case allHTTPHeaderFields
        case httpBody
        case httpShouldHandleCookies
        case httpShouldUsePipelining
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let url = try container.decode(URL.self, forKey: .url)
        let cachePolicy = try container.decode(URLRequest.CachePolicy.self, forKey: .cachePolicy)
        let timeoutInterval = try container.decode(TimeInterval.self, forKey: .timeoutInterval)

        var urlRequest = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        urlRequest.mainDocumentURL = try container.decodeIfPresent(URL.self, forKey: .mainDocumentURL)
        urlRequest.allowsCellularAccess = try container.decode(Bool.self, forKey: .allowsCelluarAccess)
        urlRequest.httpMethod = try container.decodeIfPresent(String.self, forKey: .httpMethod)
        urlRequest.allHTTPHeaderFields = try container.decodeIfPresent([String: String].self, forKey: .allHTTPHeaderFields)
        urlRequest.httpBody = try container.decodeIfPresent(Data.self, forKey: .httpBody)
        urlRequest.httpShouldHandleCookies = try container.decode(Bool.self, forKey: .httpShouldHandleCookies)
        urlRequest.httpShouldUsePipelining = try container.decode(Bool.self, forKey: .httpShouldUsePipelining)

        self = urlRequest
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(url, forKey: .url)
        try container.encode(cachePolicy, forKey: .cachePolicy)
        try container.encode(timeoutInterval, forKey: .timeoutInterval)
        try container.encodeIfPresent(mainDocumentURL, forKey: .mainDocumentURL)
        try container.encode(allowsCellularAccess, forKey: .allowsCelluarAccess)
        try container.encodeIfPresent(httpMethod, forKey: .httpMethod)
        try container.encodeIfPresent(allHTTPHeaderFields, forKey: .allHTTPHeaderFields)
        try container.encodeIfPresent(httpBody, forKey: .httpBody)
        try container.encode(httpShouldHandleCookies, forKey: .httpShouldHandleCookies)
        try container.encode(httpShouldUsePipelining, forKey: .httpShouldUsePipelining)
    }

}

extension URLRequest.CachePolicy: Codable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decodedValue = try container.decode(UInt.self)
        guard let cachePolicy = URLRequest.CachePolicy(rawValue: decodedValue) else {
            let context = DecodingError.Context.init(codingPath: decoder.codingPath, debugDescription: "Could not create CachePolicy with \(decodedValue)")
            throw DecodingError.dataCorrupted(context)
        }

        self = cachePolicy
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

}

extension URLRequest.NetworkServiceType: Codable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decodedValue = try container.decode(UInt.self)

        guard let networkServiceType = URLRequest.NetworkServiceType(rawValue: decodedValue) else {
            let context = DecodingError.Context.init(codingPath: decoder.codingPath, debugDescription: "Could not create NetworkServiceType with \(decodedValue)")
            throw DecodingError.dataCorrupted(context)
        }

        self = networkServiceType
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
