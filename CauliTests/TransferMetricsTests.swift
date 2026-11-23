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

final class TransferMetricsTests: XCTestCase {

    // MARK: - From URLSessionTaskMetrics

    func testSumsUpTheBytesOfAllTransactions() {
        let redirect = TransactionMetricsStub(requestHeader: 300, requestBody: 0, responseHeader: 200, responseBody: 0, responseBodyDecoded: 0, fetchType: .networkLoad, protocolName: "http/1.1", reused: false)
        let target = TransactionMetricsStub(requestHeader: 320, requestBody: 1_000, responseHeader: 400, responseBody: 12_000, responseBodyDecoded: 48_000, fetchType: .networkLoad, protocolName: "h2", reused: true)

        let metrics = TransferMetrics(TaskMetricsStub(transactions: [redirect, target], duration: 0.25))

        XCTAssertEqual(metrics.requestHeaderBytes, 620)
        XCTAssertEqual(metrics.requestBodyBytes, 1_000)
        XCTAssertEqual(metrics.responseHeaderBytes, 600)
        XCTAssertEqual(metrics.responseBodyBytes, 12_000)
        XCTAssertEqual(metrics.responseBodyBytesDecoded, 48_000)
        XCTAssertEqual(metrics.sentBytes, 1_620)
        XCTAssertEqual(metrics.receivedBytes, 12_600)
        XCTAssertEqual(metrics.duration, 0.25, accuracy: 0.001)
    }

    func testTakesHowTheRequestWasLoadedFromTheLastTransaction() {
        let redirect = TransactionMetricsStub(fetchType: .networkLoad, protocolName: "http/1.1", reused: false)
        let target = TransactionMetricsStub(fetchType: .localCache, protocolName: "h2", reused: true)

        let metrics = TransferMetrics(TaskMetricsStub(transactions: [redirect, target], duration: 0.1))

        XCTAssertTrue(metrics.isFromCache)
        XCTAssertEqual(metrics.networkProtocol, "h2")
        XCTAssertTrue(metrics.isReusedConnection)
    }

    func testHasNoBytesWithoutTransactions() {
        let metrics = TransferMetrics(TaskMetricsStub(transactions: [], duration: 0))

        XCTAssertEqual(metrics.sentBytes, 0)
        XCTAssertEqual(metrics.receivedBytes, 0)
        XCTAssertFalse(metrics.isFromCache)
        XCTAssertNil(metrics.networkProtocol)
    }

    // MARK: - Coding

    func testARecordKeepsItsMetricsWhenEncodedAndDecoded() throws {
        var record = Record.fake()
        record.metrics = Self.metrics

        let decoded = try JSONDecoder().decode(Record.self, from: JSONEncoder().encode(record))

        XCTAssertEqual(decoded.metrics, Self.metrics)
    }

    func testARecordWithoutMetricsCanStillBeDecoded() throws {
        // e.g. a record.json of a mock that was recorded before the metrics existed
        let encoded = try JSONEncoder().encode(Record.fake())
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        json.removeValue(forKey: "metrics")

        let decoded = try JSONDecoder().decode(Record.self, from: JSONSerialization.data(withJSONObject: json))

        XCTAssertNil(decoded.metrics)
    }

    // MARK: - Inspector

    func testTheRecordDetailsShowTheTransfer() throws {
        var record = Record.fake()
        record.result = .result(Response(URLResponse(url: URL(string: "https://cauli.works")!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil), data: nil))
        record.metrics = Self.metrics

        let items = RecordTableViewDatasource(record).sections.flatMap(\.items)

        let transfer = try XCTUnwrap(items.first { $0.title == "Transfer" })
        XCTAssertTrue(transfer.description.contains("decoded"), transfer.description)
        XCTAssertTrue(transfer.description.contains("h2"), transfer.description)
    }

    func testTheRecordDetailsShowNoTransferWithoutMetrics() {
        let items = RecordTableViewDatasource(Record.fake()).sections.flatMap(\.items)

        XCTAssertFalse(items.contains { $0.title == "Transfer" })
    }

    // MARK: - Helper

    private static let metrics = TransferMetrics(requestHeaderBytes: 320, requestBodyBytes: 0, responseHeaderBytes: 400, responseBodyBytes: 12_000, responseBodyBytesDecoded: 48_000, isFromCache: false, networkProtocol: "h2", isReusedConnection: true, duration: 0.182)
}

/// `URLSessionTaskMetrics` can't be created with values, so the tests override them.
private final class TaskMetricsStub: URLSessionTaskMetrics {
    private let transactions: [URLSessionTaskTransactionMetrics]
    private let interval: DateInterval

    init(transactions: [URLSessionTaskTransactionMetrics], duration: TimeInterval) {
        self.transactions = transactions
        self.interval = DateInterval(start: Date(), duration: duration)
        super.init()
    }

    override var transactionMetrics: [URLSessionTaskTransactionMetrics] { transactions }
    override var taskInterval: DateInterval { interval }
}

private final class TransactionMetricsStub: URLSessionTaskTransactionMetrics {
    private let values: (requestHeader: Int64, requestBody: Int64, responseHeader: Int64, responseBody: Int64, responseBodyDecoded: Int64)
    private let fetchType: URLSessionTaskMetrics.ResourceFetchType
    private let protocolName: String?
    private let reused: Bool

    init(requestHeader: Int64 = 0, requestBody: Int64 = 0, responseHeader: Int64 = 0, responseBody: Int64 = 0, responseBodyDecoded: Int64 = 0, fetchType: URLSessionTaskMetrics.ResourceFetchType, protocolName: String?, reused: Bool) {
        self.values = (requestHeader, requestBody, responseHeader, responseBody, responseBodyDecoded)
        self.fetchType = fetchType
        self.protocolName = protocolName
        self.reused = reused
        super.init()
    }

    override var countOfRequestHeaderBytesSent: Int64 { values.requestHeader }
    override var countOfRequestBodyBytesSent: Int64 { values.requestBody }
    override var countOfResponseHeaderBytesReceived: Int64 { values.responseHeader }
    override var countOfResponseBodyBytesReceived: Int64 { values.responseBody }
    override var countOfResponseBodyBytesAfterDecoding: Int64 { values.responseBodyDecoded }
    override var resourceFetchType: URLSessionTaskMetrics.ResourceFetchType { fetchType }
    override var networkProtocolName: String? { protocolName }
    override var isReusedConnection: Bool { reused }
}
