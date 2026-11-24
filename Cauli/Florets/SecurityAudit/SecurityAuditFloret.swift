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

/// The SecurityAuditFloret checks every request Cauli intercepts for privacy and security problems,
/// e.g. credentials sent over plain HTTP, tokens in URLs or insecure cookies.
///
/// ```swift
/// let audit = SecurityAuditFloret(firstPartyHosts: ["example.com"])
/// let cauli = Cauli([InspectorFloret(), audit])
/// ```
///
/// Each problem comes from a `SecurityAuditRule`. Add your own to `defaultRules`.
/// Only URLs and headers are checked, not bodies. The floret counts from its creation until `reset()`.
/// Ignored findings are kept across app starts.
public class SecurityAuditFloret: InterceptingFloret {

    /// The built-in rules.
    public static var defaultRules: [SecurityAuditRule] {
        [
            CredentialsOverHTTPRule(),
            CleartextHTTPRule(),
            SecretsInURLRule(),
            PersonalDataInURLRule(),
            OutdatedTLSRule(),
            InsecureCookieRule(),
            MissingHSTSRule()
        ]
    }

    /// If the floret is disabled, requests are not checked.
    public var enabled = true

    /// The rules every request is checked with.
    public let rules: [SecurityAuditRule]

    private static let ignoredKey = "Cauli.SecurityAuditFloret.ignored"

    private let lock = NSLock()
    private let userDefaults: UserDefaults
    private var groups: [String: Group] = [:]
    private var ignored: [SecurityAuditIgnoredFinding]
    private var checkedHosts: Set<String> = []
    private var checkedRequestsValue = 0
    private var startValue = Date()

    /// Creates the floret.
    ///
    /// - Parameters:
    ///   - rules: The rules every request is checked with.
    ///   - firstPartyHosts: The app's own hosts, e.g. ["example.com"], which includes its subdomains.
    ///     If set, personal data sent to any other host is reported by a `ThirdPartyPersonalDataRule`.
    ///   - userDefaults: Where the ignored findings are kept across app starts.
    public init(rules: [SecurityAuditRule] = SecurityAuditFloret.defaultRules, firstPartyHosts: [String] = [], userDefaults: UserDefaults = .standard) {
        let thirdPartyRule = ThirdPartyPersonalDataRule(firstPartyHosts: firstPartyHosts)
        let addsThirdPartyRule = !firstPartyHosts.isEmpty && !rules.contains { $0.identifier == thirdPartyRule.identifier }
        self.rules = addsThirdPartyRule ? rules + [thirdPartyRule] : rules
        self.userDefaults = userDefaults
        let data = userDefaults.data(forKey: SecurityAuditFloret.ignoredKey)
        ignored = data.flatMap { try? JSONDecoder().decode([SecurityAuditIgnoredFinding].self, from: $0) } ?? []
    }

    // MARK: - Findings

    /// The problems found since the floret was created or reset, the most serious first.
    /// Ignored endpoints are left out, and an issue without other endpoints too.
    public var issues: [SecurityAuditIssue] {
        lock.lock()
        defer { lock.unlock() }
        let ignoredKeys = Set(ignored.map { $0.issueIdentifier + "\n" + $0.endpoint })
        return groups.values
            .compactMap { $0.issue(ignoring: ignoredKeys) }
            .sorted { ($0.severity, $0.count, $1.title) > ($1.severity, $1.count, $0.title) }
    }

    /// How many requests were checked since the floret was created or reset.
    public var checkedRequests: Int {
        lock.lock()
        defer { lock.unlock() }
        return checkedRequestsValue
    }

    /// How many hosts the checked requests went to.
    public var checkedHostCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return checkedHosts.count
    }

    /// When the floret was created or reset.
    public var start: Date {
        lock.lock()
        defer { lock.unlock() }
        return startValue
    }

    /// Forgets all findings and starts counting again. Ignored findings stay ignored.
    public func reset() {
        lock.lock()
        groups = [:]
        checkedHosts = []
        checkedRequestsValue = 0
        startValue = Date()
        lock.unlock()
    }

    /// E.g. "1 critical finding, 3 warnings, 2 info", shown in the Cauli menu.
    public var description: String? {
        let issues = self.issues
        let count = { (severity: SecurityAuditSeverity) in issues.filter { $0.severity == severity }.count }
        let parts = [
            SecurityAuditFloret.count(count(.critical), "critical finding", "critical findings"),
            SecurityAuditFloret.count(count(.warning), "warning", "warnings"),
            SecurityAuditFloret.count(count(.info), "info", "info")
        ].compactMap { $0 }
        return parts.isEmpty ? "No findings yet. Checks requests for privacy and security problems." : parts.joined(separator: ", ")
    }

    private static func count(_ number: Int, _ singular: String, _ plural: String) -> String? {
        number < 1 ? nil : "\(number) \(number == 1 ? singular : plural)"
    }

    // MARK: - Ignoring

    /// The findings ignored for an endpoint, the most recently ignored first.
    public var ignoredFindings: [SecurityAuditIgnoredFinding] {
        lock.lock()
        defer { lock.unlock() }
        return ignored
    }

    /// Ignores the issue for all its endpoints. New endpoints with the same problem are still reported.
    public func ignore(_ issue: SecurityAuditIssue) {
        updateIgnored { ignored in
            let new = issue.endpoints.map { SecurityAuditIgnoredFinding(issueIdentifier: issue.identifier, title: issue.title, endpoint: $0.name) }
            ignored = new + ignored.filter { !new.contains($0) }
        }
    }

    /// Reports the finding again.
    public func stopIgnoring(_ finding: SecurityAuditIgnoredFinding) {
        updateIgnored { $0.removeAll { $0 == finding } }
    }

    private func updateIgnored(_ update: (inout [SecurityAuditIgnoredFinding]) -> Void) {
        lock.lock()
        update(&ignored)
        let data = try? JSONEncoder().encode(ignored)
        lock.unlock()
        userDefaults.set(data, forKey: SecurityAuditFloret.ignoredKey)
    }

    // MARK: - Checking

    /// Checks the exchange with every rule.
    func audit(_ exchange: SecurityAuditExchange, at date: Date = Date()) {
        let findings = rules.flatMap { $0.evaluate(exchange) }
        lock.lock()
        defer { lock.unlock() }
        checkedRequestsValue += 1
        if let host = exchange.host {
            checkedHosts.insert(host)
        }
        for finding in findings {
            let identifier = finding.ruleIdentifier + "\n" + finding.title
            let endpoint = SecurityAuditFloret.endpointName(of: exchange, scope: finding.scope)
            groups[identifier, default: Group(identifier: identifier)].add(finding, endpoint: endpoint, at: date)
        }
    }

    /// E.g. "GET api.example.com/users/:id", or "api.example.com" for the host scope.
    /// Ids and e-mail addresses in the path are replaced, so the name contains no personal data.
    static func endpointName(of exchange: SecurityAuditExchange, scope: SecurityAuditFinding.Scope) -> String {
        guard let url = exchange.url else { return "unknown" }
        var host = exchange.host ?? "unknown"
        if let port = url.port {
            host += ":\(port)"
        }
        guard scope == .endpoint else { return host }
        let path = EndpointPattern.pattern(for: url.path)
            .split(separator: "/", omittingEmptySubsequences: false)
            .map { PersonalDataDetector.containsPersonalData(String($0)) ? ":personal-data" : String($0) }
            .joined(separator: "/")
        return "\(exchange.request.httpMethod ?? "GET") \(host)\(path)"
    }

    // MARK: - InterceptingFloret

    /// Passes the request on unchanged.
    public func willRequest(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        completionHandler(record)
    }

    /// Checks the request and its response, then passes the response on unchanged.
    public func didRespond(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        var response: HTTPURLResponse?
        if case let .result(result)? = record.result {
            response = result.urlResponse as? HTTPURLResponse
        }
        audit(SecurityAuditExchange(request: record.designatedRequest, response: response, tlsVersion: record.metrics?.tlsVersion))
        completionHandler(record)
    }
}

/// The findings of one issue, collected per endpoint.
private struct Group {
    let identifier: String
    var severity = SecurityAuditSeverity.info
    var example: SecurityAuditFinding?
    var endpoints: [String: (count: Int, lastSeen: Date)] = [:]

    init(identifier: String) {
        self.identifier = identifier
    }

    mutating func add(_ finding: SecurityAuditFinding, endpoint: String, at date: Date) {
        severity = max(severity, finding.severity)
        example = finding
        let count = endpoints[endpoint]?.count ?? 0
        endpoints[endpoint] = (count + 1, date)
    }

    func issue(ignoring ignored: Set<String>) -> SecurityAuditIssue? {
        let visible = endpoints
            .filter { !ignored.contains(identifier + "\n" + $0.key) }
            .map { SecurityAuditIssue.Endpoint(name: $0.key, count: $0.value.count, lastSeen: $0.value.lastSeen) }
            .sorted { ($0.count, $1.name) > ($1.count, $0.name) }
        guard let example = example, !visible.isEmpty else { return nil }
        return SecurityAuditIssue(identifier: identifier, severity: severity, endpoints: visible, example: example)
    }
}
