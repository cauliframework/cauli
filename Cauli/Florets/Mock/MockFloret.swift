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

public class MockFloret: Floret {

    public enum Mode {
        case record
        case mock
    }

    public var enabled: Bool = true
    public var mode: Mode = .mock

    private lazy var recordStorage: MockFloretStorage = {
        MockFloretStorage.recorder()
    }()

    private lazy var mockStorage: MockFloretStorage? = {
        MockFloretStorage.mocker()
    }()

    public func willRequest(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) throws -> Void) {
        guard mode == .mock,
            let storage = mockStorage else { try? completionHandler(record); return }
        let storedRecord = storage.mockedRecord(record)
        let record = storedRecord ?? notFoundRecord(for: record)
        try? completionHandler(record)
    }

    public func didRespond(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) throws -> Void) {
        if mode == .record {
            recordStorage.store(record)
        }
        try? completionHandler(record)
    }
}

extension MockFloret {
    private func notFoundRecord(for record: Record) -> Record {
        var record = record
        let response = notFoundResponse(for: record.designatedRequest)
        record.result = .result(response)
        return record
    }

    private func notFoundResponse(for request: URLRequest) -> Response {
        let url = request.url ?? URL(string: "http://example.com")!
        let mimeType = request.value(forHTTPHeaderField: "accepts")
        let body = "<html><head></head><body><h1>404 - No Mock found</h1></body></html>".data(using: .utf8)!
        let urlResponse = URLResponse(url: url, mimeType: mimeType, expectedContentLength: body.count, textEncodingName: "utf-8")
        return Response(urlResponse, data: body)
    }
}
