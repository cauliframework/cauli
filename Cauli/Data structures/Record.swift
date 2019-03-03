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

    /// The originalRequest is the request passed on to the URL loading system.
    /// The originalRequest should not be changed by any floret.
    public var originalRequest: URLRequest

    /// The designatedRequest will initially be the same as the originalRequest
    /// but can be changed by every Floret. The designatedRequest is the one
    /// that will be executed in the end.
    public var designatedRequest: URLRequest

    /// The result will be nil until either the URL loading system failed to perform the
    /// request, or the response is received. The `data` of the `Response` can be incomplete
    /// while receiving.
    public var result: Result<Response>?

    /// The requestStarted Date is set after all florets finished their `willRequest` function.
    public var requestStarted: Date?

    /// The responseReceived Date is set after all florets finished their `didRespond` function.
    public var responseReceived: Date?
}

extension Record: Codable {}

extension Record {
    init(_ request: URLRequest) {
        identifier = UUID()
        originalRequest = request
        designatedRequest = request
    }
}

extension Record {
    internal mutating func append(receivedData: Data) throws {
        guard case let .result(result)? = result else {
            throw NSError.CauliInternal.appendingDataWithoutResponse(receivedData, record: self)
        }
        var currentData = result.data ?? Data()
        currentData.append(receivedData)
        self.result = .result(Response(result.urlResponse, data: currentData))
    }
}

extension Record {
    internal func swapped(to path: URL) -> SwappedRecord {
        return SwappedRecord(self, folder: path)
    }
}
