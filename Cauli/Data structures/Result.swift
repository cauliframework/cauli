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

/// The Result represents a possible result expecting any given type.
public enum Result<Type: Codable> {
    /// An error occured.
    case error(NSError)
    /// The successful result itself
    case result(Type)
}

extension Result: Codable {

    private enum CodingKeys: CodingKey {
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
            let context = DecodingError.Context.init(codingPath: decoder.codingPath, debugDescription: "Could not create Result")
            throw DecodingError.dataCorrupted(context)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .error(let error):
            try container.encode(InternalError(domain: error.domain, code: error.code, userInfo: error.compatibleUserInfo))
        case .result(let type):
            try container.encode(type)
        }
    }

}
