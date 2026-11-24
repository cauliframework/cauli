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
import Security
import XCTest

final class SecurityAuditRuleTests: XCTestCase {

    // MARK: - Credentials over HTTP

    func testCredentialsOverHTTPAreCritical() throws {
        let exchange = SecurityAuditFixture.exchange("http://api.example.com/me", headers: ["Authorization": "Bearer abcdefghijkl"])
        let finding = try XCTUnwrap(CredentialsOverHTTPRule().evaluate(exchange).first)
        XCTAssertEqual(finding.severity, .critical)
        XCTAssertEqual(finding.evidence, "Authorization: Bearer abcdefghijkl")
        XCTAssertEqual(finding.maskedEvidence, "Authorization: Bearer abcd•••", "only the token is masked")
    }

    func testCredentialsOverHTTPFindsAPasswordInTheURL() {
        let exchange = SecurityAuditFixture.exchange("http://jane:hunter2secret@api.example.com/")
        XCTAssertEqual(CredentialsOverHTTPRule().evaluate(exchange).first?.sensitiveValues, ["hunter2secret"])
    }

    func testCredentialsOverHTTPSOrToLocalhostAreFine() {
        let headers = ["Cookie": "session=1234567"]
        XCTAssertTrue(CredentialsOverHTTPRule().evaluate(SecurityAuditFixture.exchange("https://api.example.com/", headers: headers)).isEmpty)
        XCTAssertTrue(CredentialsOverHTTPRule().evaluate(SecurityAuditFixture.exchange("http://localhost:8080/", headers: headers)).isEmpty)
        XCTAssertTrue(CredentialsOverHTTPRule().evaluate(SecurityAuditFixture.exchange("http://127.0.0.1/", headers: headers)).isEmpty)
        XCTAssertTrue(CredentialsOverHTTPRule().evaluate(SecurityAuditFixture.exchange("http://api.example.com/")).isEmpty)
    }

    // MARK: - Cleartext HTTP

    func testCleartextHTTP() {
        XCTAssertEqual(CleartextHTTPRule().evaluate(SecurityAuditFixture.exchange("http://api.example.com/feed")).first?.severity, .warning)
        XCTAssertTrue(CleartextHTTPRule().evaluate(SecurityAuditFixture.exchange("https://api.example.com/feed")).isEmpty)
        XCTAssertTrue(CleartextHTTPRule().evaluate(SecurityAuditFixture.exchange("http://dev.localhost/feed")).isEmpty)
    }

    // MARK: - Secrets in URLs

    func testSecretsInURLs() throws {
        let exchange = SecurityAuditFixture.exchange("https://api.example.com/feed?page=2&access_token=eyJhbGciOiJIUzI1NiJ9&x_csrf_token=abcdef")
        let finding = try XCTUnwrap(SecretsInURLRule().evaluate(exchange).first)
        XCTAssertEqual(finding.sensitiveValues, ["eyJhbGciOiJIUzI1NiJ9", "abcdef"])
        XCTAssertEqual(finding.maskedEvidence, "https://api.example.com/feed?page=2&access_token=eyJh•••&x_csrf_token=ab•••")
        XCTAssertTrue(finding.summary.hasPrefix("access_token, x_csrf_token are sent in the URL"))
    }

    func testHarmlessParametersAreNotSecrets() {
        XCTAssertTrue(SecretsInURLRule().evaluate(SecurityAuditFixture.exchange("https://api.example.com/feed?page=2&tokenizer=on&session=")).isEmpty)
    }

    // MARK: - Personal data

    func testPersonalDataInURLs() throws {
        let exchange = SecurityAuditFixture.exchange("https://api.example.com/users/jane.doe%40example.com?phone=%2B49%20170%201234567")
        let finding = try XCTUnwrap(PersonalDataInURLRule().evaluate(exchange).first)
        XCTAssertEqual(finding.sensitiveValues, ["jane.doe@example.com", "+49 170 1234567"])
        XCTAssertTrue(finding.summary.hasPrefix("E-mail addresses and phone numbers are part of the URL"))
    }

    func testIdsAreNoPhoneNumbers() {
        XCTAssertTrue(PersonalDataInURLRule().evaluate(SecurityAuditFixture.exchange("https://api.example.com/orders/12345678?id=987654321")).isEmpty)
    }

    func testPersonalDataToThirdParties() throws {
        let rule = ThirdPartyPersonalDataRule(firstPartyHosts: ["example.com"])
        let firstParty = SecurityAuditFixture.exchange("https://api.example.com/users?email=jane@example.com")
        XCTAssertTrue(rule.evaluate(firstParty).isEmpty, "subdomains are first party")

        let thirdParty = SecurityAuditFixture.exchange("https://analytics.example.net/track", headers: ["X-User": "jane@example.com"])
        let finding = try XCTUnwrap(rule.evaluate(thirdParty).first)
        XCTAssertEqual(finding.sensitiveValues, ["jane@example.com"])
        XCTAssertEqual(finding.maskedEvidence, "https://analytics.example.net/track\nX-User: jane•••")
    }

    // MARK: - TLS

    func testOutdatedTLS() {
        XCTAssertEqual(OutdatedTLSRule().evaluate(SecurityAuditFixture.exchange("https://old.example.com/", tlsVersion: "TLS 1.1")).first?.scope, .host)
        XCTAssertTrue(OutdatedTLSRule().evaluate(SecurityAuditFixture.exchange("https://api.example.com/", tlsVersion: "TLS 1.3")).isEmpty)
        XCTAssertTrue(OutdatedTLSRule().evaluate(SecurityAuditFixture.exchange("https://api.example.com/")).isEmpty)
    }

    func testTheTLSVersionIsNamed() {
        XCTAssertEqual(TransferMetrics.name(of: .TLSv12), "TLS 1.2")
        XCTAssertEqual(TransferMetrics.name(of: .TLSv13), "TLS 1.3")
    }

    // MARK: - Cookies

    func testInsecureCookies() {
        let exchange = SecurityAuditFixture.exchange("https://api.example.com/login", responseHeaders: ["Set-Cookie": "session=abcdef123456; Path=/"])
        let findings = InsecureCookieRule().evaluate(exchange)
        XCTAssertEqual(findings.map(\.title), ["Cookies without Secure", "Cookies without HttpOnly", "Cookies without SameSite"])
        XCTAssertEqual(findings.map(\.severity), [.warning, .info, .info])
        XCTAssertEqual(findings.first?.maskedEvidence, "Set-Cookie: session=abcd•••")
    }

    func testSecureCookiesAreFine() {
        let exchange = SecurityAuditFixture.exchange("https://api.example.com/login", responseHeaders: ["Set-Cookie": "session=abcdef123456; Path=/; Secure; HttpOnly; SameSite=Lax"])
        XCTAssertTrue(InsecureCookieRule().evaluate(exchange).isEmpty)
    }

    // MARK: - HSTS

    func testMissingHSTS() {
        XCTAssertEqual(MissingHSTSRule().evaluate(SecurityAuditFixture.exchange("https://api.example.com/", responseHeaders: [:])).first?.scope, .host)
        XCTAssertTrue(MissingHSTSRule().evaluate(SecurityAuditFixture.exchange("https://api.example.com/", responseHeaders: ["strict-transport-security": "max-age=31536000"])).isEmpty)
        XCTAssertTrue(MissingHSTSRule().evaluate(SecurityAuditFixture.exchange("https://api.example.com/")).isEmpty, "a failed request has no headers to check")
    }
}
