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

/// The NetworkConditionsFloret simulates slow and unreliable networks: it delays requests and
/// responses and lets a share of them fail, with a `NetworkCondition` per host.
///
/// ```swift
/// let conditions = NetworkConditionsFloret()
/// let cauli = Cauli([InspectorFloret(), conditions])
/// conditions.defaultCondition = .threeG
/// conditions.setCondition(.offline, for: "api.example.com")
/// ```
///
/// The conditions and every host the app connected to are kept across app starts.
/// Responses reach the app at once, so bandwidth limits are simulated as a delay.
/// Only requests Cauli intercepts are affected.
public class NetworkConditionsFloret: InterceptingFloret {

    /// The maximum number of hosts remembered. The least recently used ones are forgotten first.
    public static let maximumHosts = 200

    /// If the floret is disabled, requests are passed on unchanged.
    public var enabled = true

    /// The conditions that can be selected: the presets and your own.
    public let conditions: [NetworkCondition]

    /// Returns a random number from 0 to 1 to decide whether a request fails. Replaced in tests.
    internal var random: () -> Double = { Double.random(in: 0..<1) }

    /// Calls the closure after the delay in seconds. Replaced in tests.
    internal var schedule: (TimeInterval, @escaping () -> Void) -> Void = { delay, work in
        guard delay > 0 else { return work() }
        DispatchQueue.global().asyncAfter(deadline: .now() + delay, execute: work)
    }

    private enum Key {
        static let defaultCondition = "Cauli.NetworkConditionsFloret.defaultCondition"
        static let hostConditions = "Cauli.NetworkConditionsFloret.hostConditions"
        static let hosts = "Cauli.NetworkConditionsFloret.hosts"
    }

    private let lock = NSLock()
    private let userDefaults: UserDefaults
    private var defaultConditionName: String
    private var hostConditionNames: [String: String]
    private var rememberedHosts: [String]

    /// Creates the floret.
    ///
    /// - Parameters:
    ///   - conditions: The conditions that can be selected in the Cauli menu. Add your own to the presets.
    ///     "No throttling" is always included.
    ///   - userDefaults: Where the conditions and hosts are kept across app starts.
    public init(conditions: [NetworkCondition] = NetworkCondition.presets, userDefaults: UserDefaults = .standard) {
        self.conditions = conditions.contains { $0.name == NetworkCondition.noThrottling.name } ? conditions : [.noThrottling] + conditions
        self.userDefaults = userDefaults
        defaultConditionName = userDefaults.string(forKey: Key.defaultCondition) ?? NetworkCondition.noThrottling.name
        hostConditionNames = userDefaults.dictionary(forKey: Key.hostConditions) as? [String: String] ?? [:]
        rememberedHosts = userDefaults.stringArray(forKey: Key.hosts) ?? []
    }

    // MARK: - Conditions

    /// The condition of every host without its own condition.
    public var defaultCondition: NetworkCondition {
        get {
            lock.lock()
            defer { lock.unlock() }
            return condition(named: defaultConditionName)
        }
        set {
            lock.lock()
            defaultConditionName = newValue.name
            lock.unlock()
            userDefaults.set(newValue.name, forKey: Key.defaultCondition)
        }
    }

    /// The host's own condition, `nil` if it uses the default.
    public func condition(for host: String) -> NetworkCondition? {
        lock.lock()
        defer { lock.unlock() }
        return hostConditionNames[host].map(condition(named:))
    }

    /// The condition requests to the host get: its own, else the default.
    public func effectiveCondition(for host: String) -> NetworkCondition {
        condition(for: host) ?? defaultCondition
    }

    /// Sets the host's own condition. `nil` makes it use the default.
    public func setCondition(_ condition: NetworkCondition?, for host: String) {
        lock.lock()
        hostConditionNames[host] = condition?.name
        let names = hostConditionNames
        lock.unlock()
        userDefaults.set(names, forKey: Key.hostConditions)
        remember(host)
    }

    /// Sets the default and every host to "No throttling". The hosts are kept.
    public func stopAllThrottling() {
        lock.lock()
        defaultConditionName = NetworkCondition.noThrottling.name
        hostConditionNames = [:]
        lock.unlock()
        userDefaults.set(NetworkCondition.noThrottling.name, forKey: Key.defaultCondition)
        userDefaults.set([String: String](), forKey: Key.hostConditions)
    }

    /// The hosts with a throttling condition, and the default if it throttles, e.g. for the Cauli menu.
    /// Hosts are in the order of `hosts`.
    public var activeThrottling: (defaultCondition: NetworkCondition?, hosts: [(host: String, condition: NetworkCondition)]) {
        let defaultCondition = self.defaultCondition
        let throttledHosts = hosts.compactMap { host -> (host: String, condition: NetworkCondition)? in
            guard let condition = condition(for: host), condition.isThrottling else { return nil }
            return (host, condition)
        }
        return (defaultCondition.isThrottling ? defaultCondition : nil, throttledHosts)
    }

    /// E.g. "Throttling: api.example.com (Edge), all other hosts (3G)", shown in the Cauli menu.
    public var description: String? {
        let active = activeThrottling
        var parts = active.hosts.map { "\($0.host) (\($0.condition.name))" }
        if let defaultCondition = active.defaultCondition {
            parts.append(parts.isEmpty ? "all hosts (\(defaultCondition.name))" : "all other hosts (\(defaultCondition.name))")
        }
        guard !parts.isEmpty else { return "Simulates slow and unreliable networks per host." }
        return "Throttling: " + parts.joined(separator: ", ")
    }

    // MARK: - Hosts

    /// Every host the app connected to while the floret was enabled, the most recently used first,
    /// kept across app starts.
    public var hosts: [String] {
        lock.lock()
        defer { lock.unlock() }
        return rememberedHosts
    }

    /// Forgets the host and its condition.
    public func forget(host: String) {
        lock.lock()
        rememberedHosts.removeAll { $0 == host }
        hostConditionNames[host] = nil
        let hosts = rememberedHosts
        let names = hostConditionNames
        lock.unlock()
        userDefaults.set(hosts, forKey: Key.hosts)
        userDefaults.set(names, forKey: Key.hostConditions)
    }

    private func remember(_ host: String) {
        lock.lock()
        guard rememberedHosts.first != host else {
            lock.unlock()
            return
        }
        rememberedHosts.removeAll { $0 == host }
        rememberedHosts.insert(host, at: 0)
        if rememberedHosts.count > NetworkConditionsFloret.maximumHosts {
            rememberedHosts.removeLast(rememberedHosts.count - NetworkConditionsFloret.maximumHosts)
        }
        let hosts = rememberedHosts
        lock.unlock()
        userDefaults.set(hosts, forKey: Key.hosts)
    }

    /// The condition with the name, "No throttling" if there is none, e.g. after a custom condition was removed.
    private func condition(named name: String) -> NetworkCondition {
        conditions.first { $0.name == name } ?? .noThrottling
    }

    // MARK: - InterceptingFloret

    /// Remembers the host, then delays the request by the latency and upload time, or lets it fail.
    public func willRequest(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        guard let host = record.designatedRequest.url?.host else { return completionHandler(record) }
        remember(host)
        let condition = effectiveCondition(for: host)
        guard condition.isThrottling else { return completionHandler(record) }

        var record = record
        if condition.failureRate > 0, random() < condition.failureRate {
            record.result = NetworkConditionsFloret.failureResult(condition.failure, for: record.designatedRequest)
            return schedule(condition.latency) { completionHandler(record) }
        }
        let bodyBytes = Int64(record.designatedRequest.httpBody?.count ?? 0)
        schedule(condition.requestDelay(bodyBytes: bodyBytes)) { completionHandler(record) }
    }

    /// Delays the response by the download time of its size.
    public func didRespond(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        guard let host = record.designatedRequest.url?.host,
            case let .result(response)? = record.result else { return completionHandler(record) }
        let condition = effectiveCondition(for: host)
        let bytes = record.metrics?.receivedBytes ?? Int64(response.data?.count ?? 0)
        schedule(condition.responseDelay(bytes: bytes)) { completionHandler(record) }
    }

    static func failureResult(_ failure: NetworkCondition.Failure, for request: URLRequest) -> Result<Response> {
        let url = request.url ?? URL(fileURLWithPath: "/")
        let code: Int
        switch failure {
        case .httpStatus(let statusCode):
            let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: ["X-Cauli-Simulated": "NetworkConditionsFloret"])
            return .result(Response(response ?? URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil), data: Data()))
        case .notConnectedToInternet: code = NSURLErrorNotConnectedToInternet
        case .timedOut: code = NSURLErrorTimedOut
        case .networkConnectionLost: code = NSURLErrorNetworkConnectionLost
        }
        return .error(NSError(domain: NSURLErrorDomain, code: code, userInfo: [
            NSURLErrorFailingURLErrorKey: url,
            NSLocalizedDescriptionKey: "Simulated by the NetworkConditionsFloret."
        ]))
    }
}
