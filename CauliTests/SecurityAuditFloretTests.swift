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

final class SecurityAuditFloretTests: XCTestCase {

    private var suiteName = ""
    private var userDefaults = UserDefaults.standard

    override func setUp() {
        super.setUp()
        suiteName = "SecurityAuditFloretTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private func makeFloret(firstPartyHosts: [String] = []) -> SecurityAuditFloret {
        SecurityAuditFloret(firstPartyHosts: firstPartyHosts, userDefaults: userDefaults)
    }

    func testGroupsFindingsByRuleAndEndpoint() throws {
        let floret = makeFloret()
        floret.audit(SecurityAuditFixture.exchange("https://api.example.com/feed?page=1&access_token=abcdef123456"))
        floret.audit(SecurityAuditFixture.exchange("https://api.example.com/feed?page=2&access_token=abcdef123456"))
        floret.audit(SecurityAuditFixture.exchange("https://api.example.com/users/42?token=abcdef123456"))

        let issue = try XCTUnwrap(floret.issues.first { $0.title == "Secrets in URLs" })
        XCTAssertEqual(issue.endpoints.map(\.name), ["GET api.example.com/feed", "GET api.example.com/users/:id"])
        XCTAssertEqual(issue.endpoints.map(\.count), [2, 1])
        XCTAssertEqual(issue.count, 3)
        XCTAssertEqual(floret.checkedRequests, 3)
        XCTAssertEqual(floret.checkedHostCount, 1)
    }

    func testTheMostSeriousIssuesComeFirst() {
        let floret = makeFloret()
        floret.audit(SecurityAuditFixture.exchange("https://api.example.com/", responseHeaders: [:]))
        floret.audit(SecurityAuditFixture.exchange("http://api.example.com/me", headers: ["Authorization": "Bearer abcdef123456"]))
        XCTAssertEqual(floret.issues.map(\.severity), [.critical, .warning, .info])
        XCTAssertEqual(floret.description, "1 critical finding, 1 warning, 1 info")
    }

    func testEndpointNamesContainNoPersonalData() {
        let exchange = SecurityAuditFixture.exchange("https://api.example.com:8443/users/jane%40example.com/orders/42", method: "PUT")
        XCTAssertEqual(SecurityAuditFloret.endpointName(of: exchange, scope: .endpoint), "PUT api.example.com:8443/users/:personal-data/orders/:id")
        XCTAssertEqual(SecurityAuditFloret.endpointName(of: exchange, scope: .host), "api.example.com:8443")
    }

    func testIgnoringHidesTheEndpointsAcrossAppStarts() throws {
        let floret = makeFloret()
        floret.audit(SecurityAuditFixture.exchange("http://192.168.1.20:8080/api/1"))
        let issue = try XCTUnwrap(floret.issues.first)
        floret.ignore(issue)
        XCTAssertTrue(floret.issues.isEmpty)

        let restarted = makeFloret()
        XCTAssertEqual(restarted.ignoredFindings, [SecurityAuditIgnoredFinding(issueIdentifier: issue.identifier, title: "Cleartext HTTP", endpoint: "GET 192.168.1.20:8080/api/:id")])
        restarted.audit(SecurityAuditFixture.exchange("http://192.168.1.20:8080/api/2"))
        XCTAssertTrue(restarted.issues.isEmpty, "the endpoint is still ignored")
        restarted.audit(SecurityAuditFixture.exchange("http://192.168.1.20:8080/other"))
        XCTAssertEqual(restarted.issues.first?.endpoints.map(\.name), ["GET 192.168.1.20:8080/other"], "a new endpoint is still reported")

        restarted.stopIgnoring(try XCTUnwrap(restarted.ignoredFindings.first))
        XCTAssertEqual(restarted.issues.first?.count, 2)
        XCTAssertTrue(makeFloret().ignoredFindings.isEmpty)
    }

    func testResetForgetsTheFindingsButNotTheIgnoredOnes() throws {
        let floret = makeFloret()
        floret.audit(SecurityAuditFixture.exchange("http://192.168.1.20:8080/api/1"))
        floret.ignore(try XCTUnwrap(floret.issues.first))
        floret.audit(SecurityAuditFixture.exchange("https://api.example.com/", responseHeaders: [:]))

        floret.reset()

        XCTAssertTrue(floret.issues.isEmpty)
        XCTAssertEqual(floret.checkedRequests, 0)
        XCTAssertEqual(floret.ignoredFindings.count, 1)
        XCTAssertEqual(floret.description, "No findings yet. Checks requests for privacy and security problems.")
    }

    func testFirstPartyHostsAddTheThirdPartyRule() {
        XCTAssertFalse(makeFloret().rules.contains { $0 is ThirdPartyPersonalDataRule })
        let floret = makeFloret(firstPartyHosts: ["example.com"])
        XCTAssertTrue(floret.rules.contains { $0 is ThirdPartyPersonalDataRule })
        floret.audit(SecurityAuditFixture.exchange("https://analytics.example.net/track?email=jane@example.com"))
        XCTAssertTrue(floret.issues.contains { $0.title == "Personal data to third parties" })
    }

    func testChecksTheRecordsCauliPassesOn() throws {
        let floret = makeFloret()
        let url = URL(string: "https://api.example.com/login")!
        var record = Record(URLRequest(url: url))
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Set-Cookie": "session=abcdef123456"])!
        record.result = .result(Response(response, data: nil))
        record.metrics = TransferMetrics(requestHeaderBytes: 0, requestBodyBytes: 0, responseHeaderBytes: 0, responseBodyBytes: 0, responseBodyBytesDecoded: 0, isFromCache: false, networkProtocol: "h2", isReusedConnection: false, duration: 0.1, tlsVersion: "TLS 1.0")

        let passed = waitForCompletion { floret.didRespond(record, modificationCompletionHandler: $0) }

        XCTAssertEqual(passed?.designatedRequest, record.designatedRequest)
        XCTAssertEqual(Set(floret.issues.map(\.title)), ["Cookies without Secure", "Cookies without HttpOnly", "Cookies without SameSite", "Missing HSTS", "Outdated TLS"])
    }

    func testCustomRulesAreChecked() {
        struct InternalHostRule: SecurityAuditRule {
            let identifier = "internal-host"
            func evaluate(_ exchange: SecurityAuditExchange) -> [SecurityAuditFinding] {
                guard let host = exchange.host, host.hasSuffix(".internal.example.com") else { return [] }
                return [SecurityAuditFinding(ruleIdentifier: identifier, severity: .warning, title: "Internal hosts", summary: "", evidence: host, howToFix: "", scope: .host)]
            }
        }
        let floret = SecurityAuditFloret(rules: [InternalHostRule()], userDefaults: userDefaults)
        floret.audit(SecurityAuditFixture.exchange("https://db.internal.example.com/x"))
        XCTAssertEqual(floret.issues.first?.endpoints.map(\.name), ["db.internal.example.com"])
    }
}
