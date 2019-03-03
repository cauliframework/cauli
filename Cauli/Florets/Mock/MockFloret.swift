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

/// The MockFloret helps you to easily mock your network requests
/// for tests or to reproduce a bug.
///
/// ## Recording Requests
/// ```swift
/// let mockFloret = MockFloret(mode: .record)
/// ```
/// If you create your MockFloret in recording mode it will record
/// all requests and their responses (depending on the Cauli configuration).
/// They will be serialized and stored in the document directory.
/// The exact path will be printed in the console as "`recoding to ...`".
///
/// ## Mocking Requests
/// ```swift
/// let mockFloret = MockFloret(mode: .mock)
/// ```
/// If you create your MockFloret in mock mode it will search for a `MockFloret`
/// folder in the bundle. If you used the record mode you can just copy over the
/// recorded `MockFloret` folder. Make sure to select "Create folder references" if
/// you drag the folder to Xcode.
/// For every request the MockFloret will then search in this folder if there is any
/// recorded response. If there are multiple it will return a random response.
///
/// ## Manual Response Mapping
/// You can use the `addMapping` functions to manually map a request to a specific response.
/// ```swift
/// // Maps all requests for the host cauli.works to the response
/// // stored in the MockFloret/default/foo path.
/// addMapping { request, mockFloret in
///     guard request.url?.host == "cauli.works" else { return nil }
///     return mockFloret.resultForPath("default/foo")
/// }
///
/// // Maps all requests for the url path /api/florets to
/// // a Not Found (404) response.
/// addMapping(forUrlPath: "/api/florets") { request, _ in
///     Result<Response>.notFound(for: request)
/// }
/// ```
public class MockFloret: InterceptingFloret {

    public var enabled: Bool = true

    private let mode: Mode

    /// Creates a new MockFloret instance and defines it's mode.
    ///
    /// - Parameters:
    ///   - mode: The `Mode` of this MockFloret.
    public init(mode: Mode = .mock(forced: false)) {
        self.mode = mode

        if mode == .record {
            print("recording to \(recordStorage.path)")
        }
    }

    private lazy var recordStorage: MockFloretStorage = {
        MockFloretStorage.recorder()
    }()

    private lazy var mockStorage: MockFloretStorage? = {
        MockFloretStorage.mocker()
    }()

    public func willRequest(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        guard case .mock(let forced) = mode else { completionHandler(record); return }
        var result = resultForRequest(record.designatedRequest)
        if forced && result == nil {
             result = Result<Response>.notFound(for: record.designatedRequest)
        }
        if let result = result {
            var record = record
            record.result = result
            completionHandler(record)
        } else {
            completionHandler(record)
        }
    }

    private func resultForRequest(_ request: URLRequest) -> Result<Response>? {
        guard let storage = mockStorage else {
            return nil
        }
        let manuallyMappedResponse: Result<Response>? = mappings.reduce(nil) { mappedRecord, mapping in
            mappedRecord ?? mapping.closure(request, self)
        }
        return manuallyMappedResponse ?? storage.results(for: request).randomElement()
    }

    public func didRespond(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        if mode == .record {
            recordStorage.store(record)
        }
        completionHandler(record)
    }

    /// This function will try to use the mocking storage (from within the
    /// bundle) to decode a Result by a given path.
    ///
    /// - Parameter path: The path of a record relative to the "MockFloret" folder.
    /// - Returns: A Result or nil if no decodable Record at that path.
    public func resultForPath(_ path: String) -> Result<Response>? {
        return mockStorage?.resultForPath(path)
    }

    private var mappings: [Mapping] = []
    /// A MappingClosue maps a `URLRequest` to an optional `Result`.
    public typealias MappingClosure = (URLRequest, MockFloret) -> Result<Response>?

    /// Adds a manual mapping defining which Result to use for a certain Request.
    ///
    /// - Parameter closure: A closure mapping a Request to a Result.
    /// - Returns: The Mapping. Use this object to remove the mapping at a later time.
    @discardableResult
    public func addMapping(with closure: @escaping MappingClosure) -> Mapping {
        let mapping = Mapping(closure: closure)
        mappings.append(mapping)
        return mapping
    }

    /// Adds a manual mapping defining which Result to use for a certain Request.
    /// The closure will only be applied if the path of the Requests url matches
    /// the given path.
    ///
    /// - Parameters:
    ///   - urlPath: The expected path of the requests url.
    ///   - closure: A closure mapping a Request to a Result.
    /// - Returns: The Mapping. Use this object to remove the mapping at a later time.
    @discardableResult
    public func addMapping(forUrlPath urlPath: String, with closure: @escaping MappingClosure) -> Mapping {
        return addMapping { request, floret in
            guard let path = request.url?.path,
                path == urlPath else { return nil }
            return closure(request, floret)
        }
    }

    /// Adds a manual mapping defining which Result to use for a certain Request.
    /// The closure will only be applied if the url of the Requests matches
    /// the given url.
    ///
    /// - Parameters:
    ///   - url: The expected url of the Request.
    ///   - closure: A closure mapping a Request to a Result.
    /// - Returns: The Mapping. Use this object to remove the mapping at a later time.
    @discardableResult
    public func addMapping(forUrl url: URL, with closure: @escaping MappingClosure) -> Mapping {
        return addMapping { request, floret in
            guard let requestUrl = request.url,
                requestUrl == url else { return nil }
            return closure(request, floret)
        }
    }

    /// Removes a manual Mapping. If the mapping is currently not configured
    /// it does nothing.
    ///
    /// - Parameter mapping: The mapping to remove.
    public func removeMapping(_ mapping: Mapping) {
        mappings = mappings.filter { $0.uuid != mapping.uuid }
    }

}

extension MockFloret {
    /// All possible modes the MockFloret can be in.
    public enum Mode: Equatable {
        /// In record mode the MockFloret will record all (depending on the
        /// Cauli configuration) requests, serialize and store them in the documents folder.
        case record

        /// In mock mode the MockFloret will search for a "MockFloret" folder in the Bundle
        /// and tries to map all requests to a response stored in that folder.
        /// Forced defines the behaviour if no response is found.
        /// If forced is false, the request will be ignored by the `MockFloret`.
        /// If forced is true, the request will be answered with a 404-not-found response.
        case mock(forced: Bool)
    }
}

extension MockFloret {
    /// A MockFloret.Mapping is an internal representation of a mapping from a
    /// URLRequest to a Result for a Response (`(URLRequest, MockFloret) -> Result<Response>?`).
    /// This Mapping will be returned when using the `addMapping` function and can be
    /// used to remove a Mapping via `removeMapping`.
    public struct Mapping {
        internal let uuid = UUID()
        internal let closure: MappingClosure
    }
}

extension Result {
    /// Creates an returns a not-found (404) result for the given request.
    ///
    /// - Parameter request: The request.
    /// - Returns: The not-found `Result` for the given request.
    public static func notFound(for request: URLRequest) -> Result<Response> {
        let response = Response.notFound(for: request)
        return .result(response)
    }
}

internal extension Response {
    static func notFound(for request: URLRequest) -> Response {
        // swiftlint:disable force_unwrapping
        let url = request.url ?? URL(string: "http://example.com")!
        let body = "<html><head></head><body><h1>404 - No Mock found</h1></body></html>".data(using: .utf8)!
        let urlResponse = HTTPURLResponse(url: url, statusCode: 404, httpVersion: "1.1", headerFields: nil)!
        // swiftlint:enable force_unwrapping
        return Response(urlResponse, data: body)
    }
}
