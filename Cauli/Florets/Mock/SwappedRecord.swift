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

internal struct SwappedRecord: Codable {
    let identifier: UUID
    let originalRequest: SwappedURLRequest
    let designatedRequest: SwappedURLRequest
    let result: Result<SwappedResponse>?
    let requestStarted: Date?
    let responseReceived: Date?
}

extension SwappedRecord {
    init(_ record: Record, folder: URL) {
        self.identifier = record.identifier
        self.originalRequest = SwappedURLRequest(record.originalRequest, bodyFilepath: folder.appendingPathComponent("originalRequest.data"))
        self.designatedRequest = SwappedURLRequest(record.designatedRequest, bodyFilepath: folder.appendingPathComponent("designatedRequest.data"))
        if let result = record.result {
            switch result {
            case .error(let error):
                self.result = .error(error)
            case .result(let response):
                let swappedResponse = SwappedResponse(response, dataFilepath: folder.appendingPathComponent("response.data"))
                self.result = .result(swappedResponse)
            }
        } else {
            self.result = nil
        }

        self.requestStarted = record.requestStarted
        self.responseReceived = record.responseReceived
    }

    func record(in folder: URL) -> Record {
        var record = Record(self.originalRequest.urlRequest(in: folder))

        record.identifier = self.identifier
        record.designatedRequest = self.designatedRequest.urlRequest(in: folder)
        if let result = self.result {
            switch result {
            case .error(let error):
                record.result = .error(error)
            case .result(let swappedResponse):
                let response = swappedResponse.response(in: folder)
                record.result = .result(response)
            }
        } else {
            record.result = nil
        }
        record.requestStarted = self.requestStarted
        record.responseReceived = self.responseReceived

        return record
    }
}
