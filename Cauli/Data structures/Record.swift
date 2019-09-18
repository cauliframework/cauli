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

/// A record represents a full roundtrip of a URLRequest and it's response.
public struct Record {
    /// The identifier of the record. As long as the identifier is the same
    /// two Records are assumed to be the same.
    public var identifier: UUID

    /// The request executed. Once the record is received from the storage, the
    /// httpBody will be converted to a httpBodyStream.
    public var request: URLRequest

    /// The result will be nil until either the URL loading system failed to perform the
    /// request, or the response is received. The `responseBodyStream` will be set by the 
    public var result: Result<Response>?

    /// The requestStarted Date is set after all florets finished their `willRequest` function.
    public var requestStarted: Date?

    /// The responseReceived Date is set after all florets finished their `didRespond` function.
    public var responseReceived: Date?

    /// The size of the request body data. Nil if the request body was empty.
    public var requestBodySize: Int64?

    /// The size of the response body data. Nil if the response body was empty.
    public var responseBodySize: Int64?
}

extension Record: Codable {}

extension Record {
    init(_ request: URLRequest) {
        identifier = UUID()
        self.request = request
    }
}
