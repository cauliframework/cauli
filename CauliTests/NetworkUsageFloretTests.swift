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

final class NetworkUsageFloretTests: XCTestCase {

    // MARK: - Recording

    func testCountsTheTransferOfARecordWithMetrics() throws {
        let sut = NetworkUsageFloret()

        respond(record(url: "https://api.example.com/users/42", headers: ["Content-Type": "application/json"], body: 2_000), to: sut)

        let usage = sut.snapshot
        XCTAssertEqual(usage.totals.requests, 1)
        XCTAssertEqual(usage.totals.receivedBytes, 2_200)
        XCTAssertEqual(usage.hosts.map(\.host), ["api.example.com"])
        XCTAssertEqual(usage.endpoints.map(\.name), ["GET /users/:id"])
        let transfer = try XCTUnwrap(usage.transfers.first)
        XCTAssertEqual(transfer.responseContentType, "application/json")
        XCTAssertEqual(transfer.statusCode, 200)
    }

    func testIgnoresARecordWithoutMetrics() {
        let sut = NetworkUsageFloret()
        var record = record(url: "https://api.example.com/config", headers: [:], body: 10)
        record.metrics = nil

        respond(record, to: sut)

        XCTAssertEqual(sut.snapshot.totals.requests, 0, "e.g. a mocked response wasn't transferred over the network")
    }

    func testReadsTheHeaderFieldsOfTheResponse() throws {
        let sut = NetworkUsageFloret()

        respond(record(url: "https://api.example.com/a", headers: ["content-type": "application/json; charset=utf-8", "content-encoding": "gzip", "Cache-Control": "no-store"], body: 100), to: sut)
        respond(record(url: "https://api.example.com/b", headers: ["ETag": "\"1\""], body: 100), to: sut)

        let transfers = sut.snapshot.transfers
        XCTAssertEqual(transfers[0].responseContentType, "application/json")
        XCTAssertTrue(transfers[0].isResponseCompressed)
        XCTAssertFalse(transfers[0].isCacheable, "no-store doesn't allow caching")
        XCTAssertTrue(transfers[1].isCacheable, "an ETag allows revalidating")
        XCTAssertFalse(transfers[1].isResponseCompressed)
    }

    func testResetForgetsTheUsage() {
        let sut = NetworkUsageFloret()
        respond(record(url: "https://api.example.com/config", headers: [:], body: 10), to: sut)

        sut.reset()

        XCTAssertEqual(sut.snapshot.totals, NetworkUsageTotals())
        XCTAssertTrue(sut.snapshot.transfers.isEmpty)
        XCTAssertTrue(sut.snapshot.hosts.isEmpty)
    }

    func testKeepsTheMostRecentTransfersButCountsAll() {
        let store = NetworkUsageStore(maximumTransfers: 2)

        ["/a", "/b", "/c"].forEach { store.add(NetworkUsageFixture.transfer(url: "https://api.example.com\($0)")) }

        let usage = store.snapshot()
        XCTAssertEqual(usage.transfers.map(\.endpoint), ["/b", "/c"])
        XCTAssertEqual(usage.totals.requests, 3)
        XCTAssertEqual(usage.endpoints.count, 3)
    }

    // MARK: - Totals

    func testTotals() {
        let usage = NetworkUsageFixture.snapshot([
            NetworkUsageFixture.transfer(body: 1_000, decodedBody: 4_000, reused: false),
            NetworkUsageFixture.transfer(body: 1_000, reused: true),
            NetworkUsageFixture.transfer(body: 9_000, fromCache: true)
        ])

        XCTAssertEqual(usage.totals.requests, 3)
        XCTAssertEqual(usage.totals.requestsFromCache, 1)
        XCTAssertEqual(usage.totals.receivedBodyBytes, 2_000, "responses from the cache aren't received over the network")
        XCTAssertEqual(usage.totals.savedByCompression, 3_000)
        XCTAssertEqual(usage.totals.connectionReuse, 0.5)
    }

    func testSortsHostsAndEndpointsByReceivedBytes() {
        let usage = NetworkUsageFixture.snapshot([
            NetworkUsageFixture.transfer(url: "https://small.example.com/a", body: 10),
            NetworkUsageFixture.transfer(url: "https://large.example.com/b", body: 10_000)
        ])

        XCTAssertEqual(usage.hosts.map(\.host), ["large.example.com", "small.example.com"])
        XCTAssertEqual(usage.endpoints.map(\.path), ["/b", "/a"])
    }

    // MARK: - Endpoint patterns

    func testReplacesIDsInPaths() {
        XCTAssertEqual(EndpointPattern.pattern(for: "/users/42/posts"), "/users/:id/posts")
        XCTAssertEqual(EndpointPattern.pattern(for: "/items/3F2504E0-4F89-11D3-9A0C-0305E82C3301"), "/items/:id")
        XCTAssertEqual(EndpointPattern.pattern(for: "/files/9f86d081884c7d65"), "/files/:id")
        XCTAssertEqual(EndpointPattern.pattern(for: "/v2/search"), "/v2/search")
        XCTAssertEqual(EndpointPattern.pattern(for: ""), "/")
    }

    // MARK: - Rules

    func testListsTheHintsOfCustomRulesWithTheBuiltInOnes() {
        let sut = NetworkUsageFloret(rules: NetworkUsageFloret.defaultRules + [AlwaysRule()])
        respond(record(url: "https://api.example.com/users/1", headers: ["Content-Type": "application/json"], body: 50_000), to: sut)

        let identifiers = sut.hints.map(\.ruleIdentifier)

        XCTAssertTrue(identifiers.contains("always"))
        XCTAssertEqual(identifiers.first, "uncompressed-response", "warnings are listed before infos")
    }

    func testOrdersHintsByWarningsThenSaving() {
        let hints = [
            hint("info-large", .info, saving: 10_000),
            hint("warning-small", .warning, saving: 10),
            hint("warning-none", .warning, saving: nil),
            hint("warning-large", .warning, saving: 5_000)
        ].sorted(by: NetworkUsageHint.isOrderedBefore)

        XCTAssertEqual(hints.map(\.ruleIdentifier), ["warning-large", "warning-small", "warning-none", "info-large"])
    }

    // MARK: - Export

    func testExportsTheTransfersAsCSV() {
        let sut = NetworkUsageFloret()
        respond(record(url: "https://api.example.com/search?q=a,b", headers: [:], body: 10), to: sut)

        let lines = sut.exportCSV().split(separator: "\n")

        XCTAssertEqual(lines.count, 2)
        XCTAssertTrue(lines[0].hasPrefix("date,method,host,endpoint,url"))
        XCTAssertTrue(lines[1].contains("\"https://api.example.com/search?q=a,b\""), "a url with a comma is quoted")
    }

    func testExportsTheUsageAsJSON() throws {
        let sut = NetworkUsageFloret()
        respond(record(url: "https://api.example.com/config", headers: [:], body: 10), to: sut)

        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: sut.exportJSON()) as? [String: Any])

        XCTAssertEqual(Set(json.keys), ["start", "totals", "hosts", "endpoints", "transfers"])
    }

    // MARK: - Helper

    private struct AlwaysRule: NetworkUsageRule {
        let identifier = "always"
        func evaluate(_ usage: NetworkUsageSnapshot) -> NetworkUsageHint? {
            NetworkUsageHint(ruleIdentifier: identifier, severity: .info, title: "Always", summary: "", affectedEndpoints: [], estimatedSavingBytes: nil, howToFix: "")
        }
    }

    private func hint(_ identifier: String, _ severity: NetworkUsageHint.Severity, saving: Int64?) -> NetworkUsageHint {
        NetworkUsageHint(ruleIdentifier: identifier, severity: severity, title: identifier, summary: "", affectedEndpoints: [], estimatedSavingBytes: saving, howToFix: "")
    }

    private func record(url: String, headers: [String: String], body: Int64) -> Record {
        let requestURL = URL(string: url)!
        var record = Record(URLRequest(url: requestURL))
        let response = HTTPURLResponse(url: requestURL, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)!
        record.result = .result(Response(response, data: nil))
        record.metrics = TransferMetrics(requestHeaderBytes: 300, requestBodyBytes: 0, responseHeaderBytes: 200, responseBodyBytes: body, responseBodyBytesDecoded: body, isFromCache: false, networkProtocol: "h2", isReusedConnection: true, duration: 0.1)
        return record
    }

    private func respond(_ record: Record, to floret: NetworkUsageFloret) {
        floret.didRespond(record) { _ in }
    }
}
