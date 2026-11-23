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

final class NetworkUsageRuleTests: XCTestCase {

    private typealias Fixture = NetworkUsageFixture

    // MARK: - UncompressedResponseRule

    func testUncompressedResponsesAreFound() throws {
        let usage = Fixture.snapshot([Fixture.transfer(url: "https://api.example.com/users/1", body: 3_000)])

        let hint = try XCTUnwrap(UncompressedResponseRule().evaluate(usage))

        XCTAssertEqual(hint.severity, .warning)
        XCTAssertEqual(hint.affectedEndpoints.map(\.name), ["GET /users/:id"])
        XCTAssertEqual(hint.estimatedSavingBytes, 2_000, "without compressed responses to learn from, a ratio of 3 is assumed")
    }

    func testTheSavingOfUncompressedResponsesIsEstimatedFromTheCompressedOnes() throws {
        let usage = Fixture.snapshot([
            Fixture.transfer(url: "https://api.example.com/users/1", body: 4_200),
            Fixture.transfer(url: "https://api.example.com/feed", contentEncoding: "gzip", body: 1_000, decodedBody: 4_200)
        ])

        let hint = try XCTUnwrap(UncompressedResponseRule().evaluate(usage))

        XCTAssertEqual(hint.estimatedSavingBytes, 3_200, "the feed compresses 4.2 times")
        XCTAssertEqual(hint.affectedEndpoints.map(\.name), ["GET /users/:id"])
    }

    func testCompressedSmallBinaryAndCachedResponsesAreFine() {
        let usage = Fixture.snapshot([
            Fixture.transfer(contentEncoding: "br", body: 3_000),
            Fixture.transfer(body: 500),
            Fixture.transfer(contentType: "image/png", body: 30_000),
            Fixture.transfer(body: 3_000, fromCache: true)
        ])

        XCTAssertNil(UncompressedResponseRule().evaluate(usage))
    }

    // MARK: - UncompressedUploadRule

    func testUncompressedUploadsAreFound() throws {
        let usage = Fixture.snapshot([Fixture.transfer(method: "POST", url: "https://api.example.com/events", requestBody: 6_000)])

        let hint = try XCTUnwrap(UncompressedUploadRule().evaluate(usage))

        XCTAssertEqual(hint.affectedEndpoints.map(\.name), ["POST /events"])
        XCTAssertEqual(hint.estimatedSavingBytes, 4_000)
    }

    func testCompressedAndSmallUploadsAreFine() {
        let usage = Fixture.snapshot([
            Fixture.transfer(method: "POST", requestEncoding: "gzip", requestBody: 6_000),
            Fixture.transfer(method: "POST", requestBody: 200)
        ])

        XCTAssertNil(UncompressedUploadRule().evaluate(usage))
    }

    // MARK: - DuplicateRequestRule

    func testRepeatedRequestsWithinTheWindowAreFound() throws {
        let usage = Fixture.snapshot((0..<3).map { Fixture.transfer(url: "https://api.example.com/config", date: date($0 * 2)) })

        let hint = try XCTUnwrap(DuplicateRequestRule().evaluate(usage))

        XCTAssertEqual(hint.summary, "2 requests repeated within 10 s")
        XCTAssertEqual(hint.estimatedSavingBytes, 4_400, "the bytes of the 2 repeated requests")
    }

    func testRequestsOutsideTheWindowDifferentUrlsAndPostsAreFine() {
        let spread = (0..<3).map { Fixture.transfer(url: "https://api.example.com/config", date: date($0 * 20)) }
        let differentUrls = (0..<3).map { Fixture.transfer(url: "https://api.example.com/users/\($0)") }
        let posts = (0..<3).map { _ in Fixture.transfer(method: "POST", url: "https://api.example.com/events") }

        XCTAssertNil(DuplicateRequestRule().evaluate(Fixture.snapshot(spread)))
        XCTAssertNil(DuplicateRequestRule().evaluate(Fixture.snapshot(differentUrls)))
        XCTAssertNil(DuplicateRequestRule().evaluate(Fixture.snapshot(posts)))
    }

    // MARK: - NotCacheableRule

    func testRepeatedRequestsWithoutCachingHeadersAreFound() throws {
        let usage = Fixture.snapshot((0..<3).map { Fixture.transfer(url: "https://api.example.com/config", cacheable: false, date: date($0 * 60)) })

        let hint = try XCTUnwrap(NotCacheableRule().evaluate(usage))

        XCTAssertEqual(hint.affectedEndpoints.map(\.name), ["GET /config"])
        XCTAssertNil(hint.estimatedSavingBytes)
    }

    func testCacheableAndRarelyRequestedResponsesAreFine() {
        let cacheable = (0..<3).map { _ in Fixture.transfer(url: "https://api.example.com/config", cacheable: true) }
        let rare = (0..<2).map { _ in Fixture.transfer(url: "https://api.example.com/config", cacheable: false) }

        XCTAssertNil(NotCacheableRule().evaluate(Fixture.snapshot(cacheable)))
        XCTAssertNil(NotCacheableRule().evaluate(Fixture.snapshot(rare)))
    }

    // MARK: - LargePayloadRule

    func testLargeResponsesAreFound() throws {
        let usage = Fixture.snapshot([Fixture.transfer(url: "https://images.example.com/hero.jpg", contentType: "image/jpeg", body: 820_000)])

        let hint = try XCTUnwrap(LargePayloadRule().evaluate(usage))

        XCTAssertEqual(hint.affectedEndpoints.map(\.name), ["GET /hero.jpg"])
    }

    func testSmallResponsesAreFine() {
        XCTAssertNil(LargePayloadRule().evaluate(Fixture.snapshot([Fixture.transfer(body: 400_000)])))
    }

    // MARK: - LegacyProtocolRule

    func testHostsOnlyUsingHTTP1AreFound() throws {
        let usage = Fixture.snapshot([
            Fixture.transfer(url: "https://analytics.example.net/track", protocolName: "http/1.1"),
            Fixture.transfer(url: "https://api.example.com/feed", protocolName: "h2")
        ])

        let hint = try XCTUnwrap(LegacyProtocolRule().evaluate(usage))

        XCTAssertEqual(hint.summary, "analytics.example.net")
        XCTAssertEqual(hint.affectedEndpoints.map(\.host), ["analytics.example.net"])
    }

    func testHostsAlsoUsingHTTP2AreFine() {
        let usage = Fixture.snapshot([
            Fixture.transfer(protocolName: "http/1.1"),
            Fixture.transfer(protocolName: "h2")
        ])

        XCTAssertNil(LegacyProtocolRule().evaluate(usage))
    }

    // MARK: - ConnectionReuseRule

    func testHostsReusingFewConnectionsAreFound() throws {
        let usage = Fixture.snapshot((0..<10).map { _ in Fixture.transfer(reused: false) })

        let hint = try XCTUnwrap(ConnectionReuseRule().evaluate(usage))

        XCTAssertEqual(hint.summary, "api.example.com: 10 new connections for 10 requests")
    }

    func testHostsReusingConnectionsOrWithFewRequestsAreFine() {
        let reusing = (0..<10).map { _ in Fixture.transfer(reused: true) }
        let few = (0..<5).map { _ in Fixture.transfer(reused: false) }

        XCTAssertNil(ConnectionReuseRule().evaluate(Fixture.snapshot(reusing)))
        XCTAssertNil(ConnectionReuseRule().evaluate(Fixture.snapshot(few)))
    }

    // MARK: - Helper

    private func date(_ seconds: Int) -> Date {
        Date(timeIntervalSinceReferenceDate: TimeInterval(seconds))
    }
}
