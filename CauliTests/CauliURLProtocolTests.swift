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

final class CauliURLProtocolTests: XCTestCase {

    private let url = URL(string: "https://cauli.works")!
    private var session: URLSession!

    override func setUp() {
        super.setUp()
        // Creating a Cauli installs its URL loading hooks once for the whole process, which is
        // what other tests do as well. Toggling them here would turn them off for everyone else.
        _ = Cauli([], configuration: Configuration(recordSelector: .all(), enableShakeGesture: false, storageCapacity: .records(1)))
        // We are stubbing every request.
        StubURLProtocol.enable()
        session = URLSession(configuration: .default)
        XCTAssertTrue(session.configuration.protocolClasses?.first == CauliURLProtocol.self, "requests must reach Cauli first")
        XCTAssertTrue(session.configuration.protocolClasses?.dropFirst().first == StubURLProtocol.self, "Cauli's own requests must reach the stub")
    }

    override func tearDown() {
        session.invalidateAndCancel()
        session = nil
        StubURLProtocol.disable()
        super.tearDown()
    }

    // MARK: - Regression: requests the client stops (#160)

    func testATimedOutRequestIsReportedAsTimedOut() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 1
        let timingOutSession = URLSession(configuration: configuration)
        defer { timingOutSession.invalidateAndCancel() }
        let reportedError = reportedErrorOfTheResponse()
        let failed = expectation(description: "the request failed")

        timingOutSession.dataTask(with: StubURLProtocol.hangingURL) { _, _, error in
            XCTAssertEqual((error as? URLError)?.code, .timedOut, "the app itself must see a timeout")
            failed.fulfill()
        }.resume()

        // Both normally take about a second. The generous timeouts only absorb stalls of busy CI simulators:
        // a request that is never reported still fails, and the failing wait names the late part.
        wait(for: [failed], timeout: 30)
        wait(for: [reportedError.reported], timeout: 30)
        XCTAssertEqual(reportedError.error?.code, NSURLErrorTimedOut, "Cauli must record the timeout the app saw, not a cancellation")
    }

    func testACancelledRequestIsReportedAsCancelled() {
        let reportedError = reportedErrorOfTheResponse()
        let reachedTheServer = expectation(description: "the request reached the server")
        StubURLProtocol.hangingRequestStarted = { reachedTheServer.fulfill() }
        defer { StubURLProtocol.hangingRequestStarted = nil }
        let task = session.dataTask(with: StubURLProtocol.hangingURL) { _, _, _ in }

        task.resume()
        wait(for: [reachedTheServer], timeout: 30)
        task.cancel()

        wait(for: [reportedError.reported], timeout: 30)
        XCTAssertEqual(reportedError.error?.code, NSURLErrorCancelled)
    }

    private final class ReportedError {
        var error: NSError?
        var reported: XCTestExpectation

        init(_ reported: XCTestExpectation) {
            self.reported = reported
        }
    }

    /// Captures the error of the record Cauli passes to `didRespond`, i.e. the one florets and the storage see.
    private func reportedErrorOfTheResponse() -> ReportedError {
        let delegate = CauliURLProtocolDelegateStub()
        let reportedError = ReportedError(expectation(description: "the response was reported to the florets"))
        delegate.didRespondClosure = { record in
            if case .error(let error)? = record.result {
                reportedError.error = error
            }
            reportedError.reported.fulfill()
        }
        CauliURLProtocol.add(delegate: delegate)
        addTeardownBlock { CauliURLProtocol.remove(delegate: delegate) }
        return reportedError
    }

    // MARK: - addDelegate

    func testAddDelegateCallsWillRequestOnceANetworkRequestIsPerformed() {
        let delegate = CauliURLProtocolDelegateStub()
        let willRequestCalled = expectation(description: "willRequest called")
        willRequestCalled.assertForOverFulfill = false
        delegate.willRequestClosure = { _ in willRequestCalled.fulfill() }
        CauliURLProtocol.add(delegate: delegate)

        session.dataTask(with: url) { _, _, _ in }.resume()

        wait(for: [willRequestCalled], timeout: 5)
    }

    func testAddDelegateCallsDidRespondOnceANetworkRequestIsPerformed() {
        let delegate = CauliURLProtocolDelegateStub()
        let didRespondCalled = expectation(description: "didRespond called")
        didRespondCalled.assertForOverFulfill = false
        delegate.didRespondClosure = { _ in didRespondCalled.fulfill() }
        CauliURLProtocol.add(delegate: delegate)

        session.dataTask(with: url) { _, _, _ in }.resume()

        wait(for: [didRespondCalled], timeout: 5)
    }

    // MARK: - removeDelegate

    func testRemoveDelegateStopsCallingTheDelegateFunctions() {
        let delegate = CauliURLProtocolDelegateStub()
        var didCallDelegateFunction = false
        delegate.willRequestClosure = { _ in didCallDelegateFunction = true }
        delegate.didRespondClosure = { _ in didCallDelegateFunction = true }
        CauliURLProtocol.add(delegate: delegate)
        CauliURLProtocol.remove(delegate: delegate)

        let requestFinished = expectation(description: "request finished")
        session.dataTask(with: url) { _, _, _ in requestFinished.fulfill() }.resume()

        wait(for: [requestFinished], timeout: 5)
        XCTAssertFalse(didCallDelegateFunction)
    }

    // MARK: - willRequest

    func testWillRequestEnablesToChangeTheDesignatedRequest() {
        let delegate = CauliURLProtocolDelegateStub()
        delegate.willRequestClosure = { record in
            record.designatedRequest = URLRequest(url: URL(string: "https://cauli.works/modified")!)
        }
        let didRespondRecord = recordPassedToDidRespond(of: delegate)

        XCTAssertEqual(didRespondRecord?.originalRequest.url?.absoluteString, "https://cauli.works")
        XCTAssertEqual(didRespondRecord?.designatedRequest.url?.absoluteString, "https://cauli.works/modified")
        guard case let .result(response)? = didRespondRecord?.result else {
            return XCTFail("expected the record to contain a result")
        }
        XCTAssertEqual(response.urlResponse.url?.absoluteString, "https://cauli.works/modified")
    }

    func testWillRequestEnablesToSetTheResult() {
        let delegate = CauliURLProtocolDelegateStub()
        let expectedData = Data("spec_changed_response".utf8)
        delegate.willRequestClosure = { record in
            let urlResponse = URLResponse(url: record.designatedRequest.url!, mimeType: nil, expectedContentLength: expectedData.count, textEncodingName: nil)
            record.result = .result(Response(urlResponse, data: expectedData))
        }
        let didRespondRecord = recordPassedToDidRespond(of: delegate)

        guard case let .result(response)? = didRespondRecord?.result else {
            return XCTFail("expected the record to contain a result")
        }
        XCTAssertEqual(response.data, expectedData)
    }

    func testWillRequestEnablesToSetAnErrorResult() {
        let delegate = CauliURLProtocolDelegateStub()
        let expectedError = NSError(domain: "domain", code: 0, userInfo: nil)
        delegate.willRequestClosure = { record in
            record.result = .error(expectedError)
        }
        let didRespondRecord = recordPassedToDidRespond(of: delegate)

        guard case let .error(error)? = didRespondRecord?.result else {
            return XCTFail("expected the record to contain an error")
        }
        XCTAssertEqual(error, expectedError)
    }

    // MARK: - didRespond

    func testDidRespondIsCalledWithACorrectResult() {
        let delegate = CauliURLProtocolDelegateStub()
        let didRespondRecord = recordPassedToDidRespond(of: delegate)

        guard case let .result(response)? = didRespondRecord?.result else {
            return XCTFail("expected the record to contain a result")
        }
        XCTAssertNotNil(response.data)
    }

    func testDidRespondEnablesToUpdateTheResult() {
        let delegate = CauliURLProtocolDelegateStub()
        let expectedData = Data("spec_changed_response".utf8)
        delegate.didRespondClosure = { record in
            let urlResponse = URLResponse(url: record.designatedRequest.url!, mimeType: nil, expectedContentLength: expectedData.count, textEncodingName: nil)
            record.result = .result(Response(urlResponse, data: expectedData))
        }
        CauliURLProtocol.add(delegate: delegate)

        let requestFinished = expectation(description: "request finished")
        var receivedData: Data?
        session.dataTask(with: url) { data, _, _ in
            receivedData = data
            requestFinished.fulfill()
        }.resume()

        wait(for: [requestFinished], timeout: 5)
        XCTAssertEqual(receivedData, expectedData)
    }

    // MARK: - Helper

    /// Adds the delegate, performs a request and returns the record passed to `didRespond`.
    /// An existing `didRespondClosure` is still executed before the record is captured.
    private func recordPassedToDidRespond(of delegate: CauliURLProtocolDelegateStub) -> Record? {
        let didRespondCalled = expectation(description: "didRespond called")
        didRespondCalled.assertForOverFulfill = false
        var didRespondRecord: Record?
        let existingDidRespondClosure = delegate.didRespondClosure
        delegate.didRespondClosure = { record in
            existingDidRespondClosure?(&record)
            didRespondRecord = record
            didRespondCalled.fulfill()
        }
        CauliURLProtocol.add(delegate: delegate)

        session.dataTask(with: url) { _, _, _ in }.resume()

        wait(for: [didRespondCalled], timeout: 5)
        return didRespondRecord
    }
}
