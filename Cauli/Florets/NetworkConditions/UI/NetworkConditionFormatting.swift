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

import UIKit

/// Texts and colors of the network conditions screens.
internal enum NetworkConditionFormatting {

    /// The color of a throttling condition: orange, readable on the cell background in light and dark mode.
    static let throttlingColor = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 1, green: 0.702, blue: 0.251, alpha: 1)
            : UIColor(red: 0.639, green: 0.322, blue: 0, alpha: 1)
    }

    /// E.g. "400 ms · 240 / 200 kbit/s" or "All requests fail: not connected".
    static func details(_ condition: NetworkCondition) -> String {
        guard condition.isThrottling else { return "Requests are passed on unchanged" }
        if condition.failureRate >= 1 {
            return "All requests fail: \(failure(condition.failure))"
        }
        var parts: [String] = []
        if condition.latency > 0 {
            parts.append(duration(condition.latency))
        }
        if let bandwidth = bandwidth(download: condition.downloadBytesPerSecond, upload: condition.uploadBytesPerSecond) {
            parts.append(bandwidth)
        }
        if condition.failureRate > 0 {
            parts.append("\(Int((condition.failureRate * 100).rounded()))% \(failure(condition.failure))")
        }
        return parts.joined(separator: " · ")
    }

    /// E.g. "not connected" or "HTTP 503".
    static func failure(_ failure: NetworkCondition.Failure) -> String {
        switch failure {
        case .notConnectedToInternet: return "not connected"
        case .timedOut: return "timed out"
        case .networkConnectionLost: return "connection lost"
        case .httpStatus(let statusCode): return "HTTP \(statusCode)"
        }
    }

    /// E.g. "400 ms" or "2 s".
    static func duration(_ seconds: TimeInterval) -> String {
        seconds < 1 ? "\(Int((seconds * 1_000).rounded())) ms" : "\(number(seconds)) s"
    }

    /// E.g. "240 / 200 kbit/s", "50 Mbit/s / 200 kbit/s" or "1 Mbit/s down".
    static func bandwidth(download: Double?, upload: Double?) -> String? {
        switch (download.map(bitRate), upload.map(bitRate)) {
        case let (down?, up?) where down.unit == up.unit:
            return "\(down.value) / \(up.value) \(down.unit)"
        case let (down?, up?):
            return "\(down.value) \(down.unit) / \(up.value) \(up.unit)"
        case let (down?, nil):
            return "\(down.value) \(down.unit) down"
        case let (nil, up?):
            return "\(up.value) \(up.unit) up"
        case (nil, nil):
            return nil
        }
    }

    private static func bitRate(bytesPerSecond: Double) -> (value: String, unit: String) {
        let bits = bytesPerSecond * 8
        if bits >= 1_000_000 {
            return (number(bits / 1_000_000), "Mbit/s")
        }
        return (number(bits / 1_000), "kbit/s")
    }

    private static func number(_ value: Double) -> String {
        value.rounded() == value ? "\(Int(value))" : String(format: "%.1f", value)
    }
}
