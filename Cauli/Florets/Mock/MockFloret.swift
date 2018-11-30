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
    public var mode: Mode = .mock {
        didSet {
            if mode == .record {
                print("recording to \(recordStorage.path)")
            }
        }
    }

    public init() {}

    private lazy var recordStorage: MockFloretStorage = {
        MockFloretStorage.recorder()
    }()

    private lazy var mockStorage: MockFloretStorage? = {
        MockFloretStorage.mocker()
    }()

    public func willRequest(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        guard mode == .mock else { completionHandler(record); return }
        let result = resultForRequest(record.designatedRequest) ?? notFoundResult(for: record.designatedRequest)
        var record = record
        record.result = result
        completionHandler(record)
    }

    private func resultForRequest(_ request: URLRequest) -> Result<Response>? {
        guard let storage = mockStorage else {
            return nil
        }
        let manuallyMappedResponse: Result<Response>? = mappings.reduce(nil) { mappedRecord, mapping in
            mappedRecord ?? mapping.closure(request, self)
        }
        return manuallyMappedResponse ?? storage.mockedResult(for: request)
    }

    public func didRespond(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        if mode == .record {
            recordStorage.store(record)
        }
        completionHandler(record)
    }

    public func resultForPath(_ path: String) -> Result<Response>? {
        return mockStorage?.resultForPath(path)
    }

    private var mappings: [Mapping] = []
    public typealias MappingClosure = (URLRequest, MockFloret) -> Result<Response>?

    @discardableResult
    public func addMapping(with closure: @escaping MappingClosure) -> Mapping {
        let mapping = Mapping(closure: closure)
        mappings.append(mapping)
        return mapping
    }

    @discardableResult
    public func addMapping(forUrlPath urlPath: String, with closure: @escaping MappingClosure) -> Mapping {
        return addMapping { request, floret in
            guard let path = request.url?.path,
                path == urlPath else { return nil }
            return closure(request, floret)
        }
    }

    @discardableResult
    public func addMapping(forUrl url: URL, with closure: @escaping MappingClosure) -> Mapping {
        return addMapping { request, floret in
            guard let requestUrl = request.url,
                requestUrl == url else { return nil }
            return closure(request, floret)
        }
    }

    public func removeMapping(_ mapping: Mapping) {
        mappings = mappings.filter { $0.uuid != mapping.uuid }
    }

}

extension MockFloret {
    public struct Mapping {
        internal let uuid = UUID()
        internal let closure: MappingClosure
    }
}

extension MockFloret {
    private func notFoundResult(for request: URLRequest) -> Result<Response> {
        let response = notFoundResponse(for: request)
        return .result(response)
    }

    private func notFoundResponse(for request: URLRequest) -> Response {
        let url = request.url ?? URL(string: "http://example.com")!

        let body = "<html><head></head><body><h1>404 - No Mock found</h1></body></html>".data(using: .utf8)!
        let urlResponse = HTTPURLResponse(url: url, statusCode: 404, httpVersion: "1.1", headerFields: nil)!
        return Response(urlResponse, data: body)
    }
}
