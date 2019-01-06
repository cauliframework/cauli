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

public struct Record: Codable {
    public var identifier: UUID
    public var originalRequest: URLRequest
    public var designatedRequest: URLRequest
    public var result: Result<Response>?
    public var requestStarted: Date?
    public var responseRecieved: Date?
}

extension Record {
    init(_ request: URLRequest) {
        identifier = UUID()
        originalRequest = request
        designatedRequest = request
    }
}

extension Record {
    mutating func append(_ receivedData: Data) throws {
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
