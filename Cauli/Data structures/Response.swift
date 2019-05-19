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

/// The `Response` wrapps the `URLResponse` and the data received from the server.
public struct Response {
    /// The `Data` received for a request.
    public var responseBodyStream: InputStream?

    /// The `URLResponse` for a request.
    public var urlResponse: URLResponse {
        get {
            return urlResponseRepresentable.urlResponse
        }
        set {
            urlResponseRepresentable = URLResponseRepresentable(newValue)
        }
    }

    /// Initializes a new `Response` with a given `URLResponse` and optional data.
    ///
    /// - Parameters:
    ///   - urlResponse: The URLResponse
    ///   - responseBodyStream: The data received for a request.
    init(_ urlResponse: URLResponse, responseBodyStream: InputStream?) {
        self.responseBodyStream = responseBodyStream
        urlResponseRepresentable = URLResponseRepresentable(urlResponse)
    }

    private var urlResponseRepresentable: URLResponseRepresentable
}

extension Response: Codable {

    private enum CodingKeys: CodingKey {
        case response
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let response = try container.decode(URLResponseRepresentable.self)
        self.urlResponseRepresentable = response
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(urlResponseRepresentable)
    }

}
