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

/// How the `NetworkConditionsFloret` changes the requests to a host: added latency,
/// limited bandwidth and failing requests.
public struct NetworkCondition: Equatable {

    /// How a failing request fails.
    public enum Failure: Equatable {
        /// `NSURLErrorNotConnectedToInternet`, as if the device were offline.
        case notConnectedToInternet
        /// `NSURLErrorTimedOut`.
        case timedOut
        /// `NSURLErrorNetworkConnectionLost`.
        case networkConnectionLost
        /// A response with this HTTP status code and an empty body, e.g. 503.
        case httpStatus(Int)
    }

    /// The name shown in the Cauli menu. It identifies the condition, e.g. when it is restored after a restart.
    public var name: String

    /// Added before every request, in seconds.
    public var latency: TimeInterval

    /// The download bandwidth in bytes per second. `nil` for unlimited.
    public var downloadBytesPerSecond: Double?

    /// The upload bandwidth in bytes per second. `nil` for unlimited.
    public var uploadBytesPerSecond: Double?

    /// The share of requests that fail, from 0 to 1.
    public var failureRate: Double

    /// How the failing requests fail.
    public var failure: Failure

    /// Creates a condition.
    public init(name: String, latency: TimeInterval = 0, downloadBytesPerSecond: Double? = nil, uploadBytesPerSecond: Double? = nil, failureRate: Double = 0, failure: Failure = .networkConnectionLost) {
        self.name = name
        self.latency = latency
        self.downloadBytesPerSecond = downloadBytesPerSecond
        self.uploadBytesPerSecond = uploadBytesPerSecond
        self.failureRate = failureRate
        self.failure = failure
    }

    /// `false` for a condition that leaves requests unchanged.
    public var isThrottling: Bool {
        latency > 0 || downloadBytesPerSecond != nil || uploadBytesPerSecond != nil || failureRate > 0
    }

    /// The delay before a request with a body of the given size is sent: the latency plus the upload time.
    public func requestDelay(bodyBytes: Int64) -> TimeInterval {
        latency + NetworkCondition.transferTime(bytes: bodyBytes, bytesPerSecond: uploadBytesPerSecond)
    }

    /// The delay before a response of the given size reaches the app: the download time.
    public func responseDelay(bytes: Int64) -> TimeInterval {
        NetworkCondition.transferTime(bytes: bytes, bytesPerSecond: downloadBytesPerSecond)
    }

    private static func transferTime(bytes: Int64, bytesPerSecond: Double?) -> TimeInterval {
        guard let bytesPerSecond = bytesPerSecond, bytesPerSecond > 0, bytes > 0 else { return 0 }
        return Double(bytes) / bytesPerSecond
    }
}

// MARK: - Presets

public extension NetworkCondition {

    /// Leaves requests unchanged.
    static let noThrottling = NetworkCondition(name: "No throttling")

    /// 50 ms, 50 Mbit/s down, 10 Mbit/s up.
    static let lte = NetworkCondition(name: "LTE", latency: 0.05, downloadBytesPerSecond: 6_250_000, uploadBytesPerSecond: 1_250_000)

    /// 100 ms, 780 kbit/s down, 330 kbit/s up.
    static let threeG = NetworkCondition(name: "3G", latency: 0.1, downloadBytesPerSecond: 97_500, uploadBytesPerSecond: 41_250)

    /// 400 ms, 240 kbit/s down, 200 kbit/s up.
    static let edge = NetworkCondition(name: "Edge", latency: 0.4, downloadBytesPerSecond: 30_000, uploadBytesPerSecond: 25_000)

    /// 500 ms, 1 Mbit/s down and up, 10% of the requests lose the connection.
    static let veryBadNetwork = NetworkCondition(name: "Very bad network", latency: 0.5, downloadBytesPerSecond: 125_000, uploadBytesPerSecond: 125_000, failureRate: 0.1, failure: .networkConnectionLost)

    /// Every request fails as if the device were offline.
    static let offline = NetworkCondition(name: "Offline", failureRate: 1, failure: .notConnectedToInternet)

    /// The presets, following Apple's Network Link Conditioner.
    static let presets: [NetworkCondition] = [.noThrottling, .lte, .threeG, .edge, .veryBadNetwork, .offline]
}
