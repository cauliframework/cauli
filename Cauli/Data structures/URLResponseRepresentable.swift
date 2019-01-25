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

internal enum URLResponseRepresentable {
    case urlResponse(URLResponse)
    case httpURLResponse(HTTPURLResponse)

    internal var urlResponse: URLResponse {
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

extension URLResponseRepresentable: Encodable {
    enum CodingKeys: CodingKey {
        case urlResponse
        case httpURLResponse
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .urlResponse(let urlResponse):
            try container.encode(urlResponse.codable, forKey: .urlResponse)
        case .httpURLResponse(let httpURLResponse):
            try container.encode(httpURLResponse.httpUrlResponseCodable, forKey: .httpURLResponse)
        }
    }
}

extension URLResponseRepresentable: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            let urlResponse = try container.decode(URLResponse.Codable.self, forKey: .urlResponse)
            self = .urlResponse(urlResponse.object)
        } catch {
            let httpURLResponse = try container.decode(HTTPURLResponse.HTTPURLResponseCodable.self, forKey: .httpURLResponse)
            self = .httpURLResponse(httpURLResponse.object)
        }
    }
}

extension URLResponse {
    var codable: Codable {
        return Codable(object: self)
    }
    struct Codable: Swift.Codable {
        let object: URLResponse

        // swiftlint:disable nesting
        enum CodingKeys: String, CodingKey {
            case url
            case mimeType
            case expectedContentLength
            case textEncodingName
        }
        // swiftlint:enable nesting

        init(object: URLResponse) {
            self.object = object
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let url = try container.decode(URL.self, forKey: .url)
            let mimeType = try? container.decode(String.self, forKey: .mimeType)
            let expectedContentLength = try container.decode(Int.self, forKey: .expectedContentLength)
            let textEncodingName = try? container.decode(String.self, forKey: .textEncodingName)

            object = URLResponse(url: url, mimeType: mimeType, expectedContentLength: expectedContentLength, textEncodingName: textEncodingName)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(object.url, forKey: .url)
            try container.encode(object.mimeType, forKey: .mimeType)
            try container.encode(object.expectedContentLength, forKey: .expectedContentLength)
            try container.encode(object.textEncodingName, forKey: .textEncodingName)
        }
    }
}

extension HTTPURLResponse {
    var httpUrlResponseCodable: HTTPURLResponseCodable {
        return HTTPURLResponseCodable(object: self)
    }
    struct HTTPURLResponseCodable: Swift.Codable {
        let object: HTTPURLResponse

        // swiftlint:disable nesting
        enum CodingKeys: String, CodingKey {
            case url
            case statusCode
            case headerFields
        }
        // swiftlint:enable nesting

        init(object: HTTPURLResponse) {
            self.object = object
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let url = try container.decode(URL.self, forKey: .url)
            let statusCode = try container.decode(Int.self, forKey: .statusCode)
            let headerFields = try? container.decode([String: String].self, forKey: .headerFields)

            if let object = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: headerFields) {
                self.object = object
            } else {
                let context = DecodingError.Context.init(codingPath: decoder.codingPath, debugDescription: "Could not initialize a HTTPURLResponse with the given data")
                throw DecodingError.dataCorrupted(context)
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(object.url, forKey: .url)
            try container.encode(object.statusCode, forKey: .statusCode)
            let headerFields = object.allHeaderFields as? [String: String] ?? [:]
            try container.encode(headerFields, forKey: .headerFields)
        }
    }
}
