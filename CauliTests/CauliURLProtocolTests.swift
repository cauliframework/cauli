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

    override func setUp() {
        super.setUp()
        // we are stubbing every request
        StubURLProtocol.enable()
        URLSessionConfiguration.cauliSwizzleDefaultSessionConfigurationGetter()
        URLProtocol.registerClass(CauliURLProtocol.self)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(CauliURLProtocol.self)
        URLSessionConfiguration.cauliSwizzleDefaultSessionConfigurationGetter()
        StubURLProtocol.disable()
        super.tearDown()
    }

    // MARK: - addDelegate

    func testAddDelegateCallsWillRequestOnceANetworkRequestIsPerformed() {
        let delegate = CauliURLProtocolDelegateStub()
        let willRequestCalled = expectation(description: "willRequest called")
        willRequestCalled.assertForOverFulfill = false
        delegate.willRequestClosure = { _ in willRequestCalled.fulfill() }
        CauliURLProtocol.add(delegate: delegate)

        URLSession.shared.dataTask(with: url) { _, _, _ in }.resume()

        wait(for: [willRequestCalled], timeout: 5)
    }

    func testAddDelegateCallsDidRespondOnceANetworkRequestIsPerformed() {
        let delegate = CauliURLProtocolDelegateStub()
        let didRespondCalled = expectation(description: "didRespond called")
        didRespondCalled.assertForOverFulfill = false
        delegate.didRespondClosure = { _ in didRespondCalled.fulfill() }
        CauliURLProtocol.add(delegate: delegate)

        URLSession.shared.dataTask(with: url) { _, _, _ in }.resume()

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
        URLSession.shared.dataTask(with: url) { _, _, _ in requestFinished.fulfill() }.resume()

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
        URLSession.shared.dataTask(with: url) { data, _, _ in
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

        URLSession.shared.dataTask(with: url) { _, _, _ in }.resume()

        wait(for: [didRespondCalled], timeout: 5)
        return didRespondRecord
    }
}
