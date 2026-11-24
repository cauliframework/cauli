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

final class NetworkConditionsFloretTests: XCTestCase {

    private var suiteName = ""
    private var userDefaults = UserDefaults.standard
    private var delays: [TimeInterval] = []

    override func setUp() {
        super.setUp()
        suiteName = "NetworkConditionsFloretTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
        delays = []
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private func makeFloret(conditions: [NetworkCondition] = NetworkCondition.presets, random: Double = 0.5) -> NetworkConditionsFloret {
        let floret = NetworkConditionsFloret(conditions: conditions, userDefaults: userDefaults)
        floret.random = { random }
        floret.schedule = { [weak self] delay, work in
            self?.delays.append(delay)
            work()
        }
        return floret
    }

    private func record(_ url: String, body: Data? = nil) -> Record {
        var request = URLRequest(url: URL(string: url)!)
        request.httpBody = body
        return Record(request)
    }

    private func responded(_ record: Record, bytes: Int) -> Record {
        var record = record
        let response = HTTPURLResponse(url: record.designatedRequest.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        record.result = .result(Response(response, data: Data(count: bytes)))
        return record
    }

    // MARK: - NetworkCondition

    func testConditionDelays() {
        let condition = NetworkCondition(name: "Test", latency: 0.2, downloadBytesPerSecond: 1_000, uploadBytesPerSecond: 500)
        XCTAssertEqual(condition.requestDelay(bodyBytes: 1_000), 2.2, accuracy: 0.0001)
        XCTAssertEqual(condition.responseDelay(bytes: 3_000), 3, accuracy: 0.0001)
        XCTAssertEqual(NetworkCondition.noThrottling.requestDelay(bodyBytes: 1_000_000), 0)
        XCTAssertEqual(NetworkCondition.noThrottling.responseDelay(bytes: 1_000_000), 0)
    }

    func testOnlyNoThrottlingDoesNotThrottle() {
        XCTAssertFalse(NetworkCondition.noThrottling.isThrottling)
        XCTAssertTrue(NetworkCondition.presets.dropFirst().allSatisfy { $0.isThrottling })
    }

    func testNoThrottlingIsAlwaysAvailable() {
        let custom = NetworkCondition(name: "Custom", latency: 1)
        let floret = makeFloret(conditions: [custom])
        XCTAssertEqual(floret.conditions.map { $0.name }, ["No throttling", "Custom"])
    }

    // MARK: - Conditions per host

    func testHostConditionOverridesTheDefault() {
        let floret = makeFloret()
        floret.defaultCondition = .threeG
        floret.setCondition(.edge, for: "api.example.com")
        XCTAssertEqual(floret.effectiveCondition(for: "api.example.com"), .edge)
        XCTAssertEqual(floret.effectiveCondition(for: "other.example.com"), .threeG)
        floret.setCondition(nil, for: "api.example.com")
        XCTAssertNil(floret.condition(for: "api.example.com"))
        XCTAssertEqual(floret.effectiveCondition(for: "api.example.com"), .threeG)
    }

    func testConditionsAndHostsArePersisted() {
        let floret = makeFloret()
        floret.defaultCondition = .lte
        floret.setCondition(.offline, for: "api.example.com")
        _ = waitForCompletion { floret.willRequest(record("https://images.example.com/a.png"), modificationCompletionHandler: $0) }

        let restarted = makeFloret()
        XCTAssertEqual(restarted.defaultCondition, .lte)
        XCTAssertEqual(restarted.condition(for: "api.example.com"), .offline)
        XCTAssertEqual(restarted.hosts, ["images.example.com", "api.example.com"])
    }

    func testUnknownPersistedConditionFallsBackToNoThrottling() {
        let custom = NetworkCondition(name: "Slow API", latency: 2)
        let floret = makeFloret(conditions: NetworkCondition.presets + [custom])
        floret.setCondition(custom, for: "api.example.com")
        let restarted = makeFloret()
        XCTAssertEqual(restarted.condition(for: "api.example.com"), .noThrottling)
    }

    func testStopAllThrottlingKeepsTheHosts() {
        let floret = makeFloret()
        floret.defaultCondition = .edge
        floret.setCondition(.offline, for: "api.example.com")
        floret.stopAllThrottling()
        XCTAssertEqual(floret.defaultCondition, .noThrottling)
        XCTAssertNil(floret.condition(for: "api.example.com"))
        XCTAssertEqual(floret.hosts, ["api.example.com"])
        XCTAssertEqual(makeFloret().defaultCondition, .noThrottling)
    }

    func testForgetRemovesTheHostAndItsCondition() {
        let floret = makeFloret()
        floret.setCondition(.offline, for: "api.example.com")
        floret.forget(host: "api.example.com")
        XCTAssertEqual(floret.hosts, [])
        XCTAssertNil(floret.condition(for: "api.example.com"))
        XCTAssertEqual(makeFloret().hosts, [])
    }

    // MARK: - Hosts

    func testHostsAreRememberedMostRecentFirst() {
        let floret = makeFloret()
        for url in ["https://a.example.com/1", "https://b.example.com/1", "https://a.example.com/2"] {
            _ = waitForCompletion { floret.willRequest(record(url), modificationCompletionHandler: $0) }
        }
        XCTAssertEqual(floret.hosts, ["a.example.com", "b.example.com"])
    }

    func testHostsAreCapped() {
        let floret = makeFloret()
        for index in 0...NetworkConditionsFloret.maximumHosts {
            _ = waitForCompletion { floret.willRequest(record("https://host\(index).example.com"), modificationCompletionHandler: $0) }
        }
        XCTAssertEqual(floret.hosts.count, NetworkConditionsFloret.maximumHosts)
        XCTAssertEqual(floret.hosts.first, "host\(NetworkConditionsFloret.maximumHosts).example.com")
        XCTAssertFalse(floret.hosts.contains("host0.example.com"))
    }

    // MARK: - Intercepting

    func testNoThrottlingPassesTheRequestOnWithoutDelay() {
        let floret = makeFloret()
        let original = record("https://api.example.com/a")
        let modified = waitForCompletion { floret.willRequest(original, modificationCompletionHandler: $0) }
        XCTAssertEqual(modified?.designatedRequest, original.designatedRequest)
        XCTAssertNil(modified?.result)
        XCTAssertEqual(delays, [])
    }

    func testRequestIsDelayedByLatencyAndUpload() {
        let floret = makeFloret()
        floret.setCondition(NetworkCondition(name: "Test", latency: 0.5, uploadBytesPerSecond: 1_000), for: "api.example.com")
        let modified = waitForCompletion { floret.willRequest(record("https://api.example.com/a", body: Data(count: 2_000)), modificationCompletionHandler: $0) }
        XCTAssertNil(modified?.result)
        XCTAssertEqual(delays.count, 1)
        XCTAssertEqual(delays.first ?? 0, 2.5, accuracy: 0.0001)
    }

    func testResponseIsDelayedByItsSize() {
        let floret = makeFloret()
        floret.defaultCondition = NetworkCondition(name: "Test", downloadBytesPerSecond: 1_000)
        _ = waitForCompletion { floret.didRespond(responded(record("https://api.example.com/a"), bytes: 4_000), modificationCompletionHandler: $0) }
        XCTAssertEqual(delays.first ?? 0, 4, accuracy: 0.0001)
    }

    func testResponseDelayUsesTheBytesReceivedOverTheNetwork() {
        let floret = makeFloret()
        floret.defaultCondition = NetworkCondition(name: "Test", downloadBytesPerSecond: 1_000)
        var record = responded(record("https://api.example.com/a"), bytes: 10_000)
        record.metrics = TransferMetrics(requestHeaderBytes: 0, requestBodyBytes: 0, responseHeaderBytes: 500, responseBodyBytes: 1_500, responseBodyBytesDecoded: 10_000, isFromCache: false, networkProtocol: "h2", isReusedConnection: false, duration: 0.1)
        _ = waitForCompletion { floret.didRespond(record, modificationCompletionHandler: $0) }
        XCTAssertEqual(delays.first ?? 0, 2, accuracy: 0.0001)
    }

    func testOfflineFailsWithNotConnectedToInternet() {
        let floret = makeFloret()
        floret.setCondition(.offline, for: "api.example.com")
        let modified = waitForCompletion { floret.willRequest(record("https://api.example.com/a"), modificationCompletionHandler: $0) }
        guard case let .error(error)? = modified?.result else { return XCTFail("Expected an error") }
        XCTAssertEqual(error.domain, NSURLErrorDomain)
        XCTAssertEqual(error.code, NSURLErrorNotConnectedToInternet)
        XCTAssertEqual(error.userInfo[NSURLErrorFailingURLErrorKey] as? URL, URL(string: "https://api.example.com/a"))
    }

    func testFailureRateDecidesWhetherARequestFails() {
        let failing = makeFloret(random: 0.05)
        failing.defaultCondition = .veryBadNetwork
        let failed = waitForCompletion { failing.willRequest(record("https://api.example.com/a"), modificationCompletionHandler: $0) }
        guard case let .error(error)? = failed?.result else { return XCTFail("Expected an error") }
        XCTAssertEqual(error.code, NSURLErrorNetworkConnectionLost)
        XCTAssertEqual(delays, [NetworkCondition.veryBadNetwork.latency])

        let passing = makeFloret(random: 0.5)
        let passed = waitForCompletion { passing.willRequest(record("https://api.example.com/a"), modificationCompletionHandler: $0) }
        XCTAssertNil(passed?.result)
    }

    func testHTTPStatusFailureReturnsAResponse() {
        let floret = makeFloret()
        floret.defaultCondition = NetworkCondition(name: "Broken API", failureRate: 1, failure: .httpStatus(503))
        let modified = waitForCompletion { floret.willRequest(record("https://api.example.com/a"), modificationCompletionHandler: $0) }
        guard case let .result(response)? = modified?.result else { return XCTFail("Expected a response") }
        XCTAssertEqual((response.urlResponse as? HTTPURLResponse)?.statusCode, 503)
    }

    // MARK: - Description

    func testDescriptionListsTheThrottledHosts() {
        let floret = makeFloret()
        XCTAssertEqual(floret.description, "Simulates slow and unreliable networks per host.")
        floret.setCondition(.edge, for: "api.example.com")
        floret.setCondition(.noThrottling, for: "images.example.com")
        XCTAssertEqual(floret.description, "Throttling: api.example.com (Edge)")
        floret.defaultCondition = .threeG
        XCTAssertEqual(floret.description, "Throttling: api.example.com (Edge), all other hosts (3G)")
        floret.setCondition(nil, for: "api.example.com")
        XCTAssertEqual(floret.description, "Throttling: all hosts (3G)")
    }
}
