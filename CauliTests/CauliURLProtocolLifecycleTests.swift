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

@testable import Cauliframework
import Foundation
import XCTest

/// Drives a `CauliURLProtocol` directly through its `URLSession` delegate methods,
/// so that the order and size of the delivered chunks is deterministic.
final class CauliURLProtocolLifecycleTests: XCTestCase {

    private let url = URL(string: "https://cauli.works/large")!
    private var delegate: CauliURLProtocolDelegateStub!
    private var client: URLProtocolClientSpy!
    private var session: URLSession!
    private var task: URLSessionDataTask!

    override func setUp() {
        super.setUp()
        delegate = CauliURLProtocolDelegateStub()
        CauliURLProtocol.add(delegate: delegate)
        client = URLProtocolClientSpy()
        session = URLSession(configuration: .ephemeral)
        task = session.dataTask(with: url) // never resumed, only passed to the delegate methods
    }

    override func tearDown() {
        CauliURLProtocol.remove(delegate: delegate)
        session.invalidateAndCancel()
        delegate = nil
        client = nil
        session = nil
        task = nil
        super.tearDown()
    }

    // MARK: - Regression: records that stop being handled while the response is loading

    /// Mirrors `RecordSelector.max(bytesize:)`: once more than `limit` bytes are buffered,
    /// the record is no longer handled and Cauli switches to passing the data through.
    func testDeliversEveryByteExactlyOnceWhenARecordStopsBeingHandledWhileLoading() {
        let limit = 10
        delegate.handlesClosure = { record in
            guard case .result(let response)? = record.result else { return true }
            return (response.data?.count ?? 0) <= limit
        }
        let chunks = (1...4).map { Data(repeating: UInt8($0), count: 8) }
        let sut = makeProtocol()

        receive(response: httpResponse(), chunks: chunks, on: sut)

        XCTAssertEqual(client.receivedData, chunks.reduce(Data(), +), "the client must receive the response body exactly once and in order")
    }

    func testDeliversTheResponseBeforeAnyDataWhenARecordIsNotHandled() {
        // Handles the request, but not the response, e.g. because its Content-Length exceeds the limit.
        delegate.handlesClosure = { record in record.result == nil }
        let chunk = Data(repeating: 1, count: 8)
        let sut = makeProtocol()

        receive(response: httpResponse(), chunks: [chunk], on: sut)

        XCTAssertEqual(client.events.first, .response, "URLProtocolClient requires the response to be delivered before any data")
        XCTAssertEqual(client.receivedData, chunk)
    }

    // MARK: - Regression: cancelling a request while the florets are still working

    func testFinishingWillRequestAfterStopLoadingDoesNotStartTheRequest() {
        var pendingCompletion: ((Record) -> Void)?
        delegate.willRequestHandler = { _, completion in
            pendingCompletion = completion // e.g. a floret that does some async work
        }
        let sut = makeProtocol()

        sut.startLoading()
        sut.stopLoading()
        // Currently this creates a task on the already invalidated session, which raises
        // "Task created in a session that has been invalidated" and crashes the test.
        pendingCompletion?(Record(URLRequest(url: url)))

        XCTAssertNotNil(pendingCompletion, "the delegate should have been asked to modify the request")
        XCTAssertEqual(client.events, [], "a stopped protocol must not report anything to its client")
    }

    // MARK: - Helper

    private func makeProtocol() -> CauliURLProtocol {
        CauliURLProtocol(request: URLRequest(url: url), cachedResponse: nil, client: client)
    }

    private func httpResponse() -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:])!
    }

    private func receive(response: URLResponse, chunks: [Data], on sut: CauliURLProtocol) {
        sut.urlSession(session, dataTask: task, didReceive: response) { _ in }
        chunks.forEach { sut.urlSession(session, dataTask: task, didReceive: $0) }
        sut.urlSession(session, task: task, didCompleteWithError: nil)
    }
}
