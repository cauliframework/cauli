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

/// Formats the values the NetworkUsageFloret's screens show.
internal enum NetworkUsageFormatting {

    /// E.g. "1.1 MB".
    static func bytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    /// E.g. "~0.8 MB" for an estimated saving.
    static func estimate(_ bytes: Int64) -> String {
        "~" + self.bytes(bytes)
    }

    /// E.g. "94%".
    static func percent(_ share: Double) -> String {
        "\(Int((share * 100).rounded()))%"
    }

    /// E.g. "182 ms" or "2.4 s".
    static func duration(_ duration: TimeInterval) -> String {
        duration < 1 ? "\(Int((duration * 1_000).rounded())) ms" : String(format: "%.1f s", duration)
    }

    /// E.g. "Since 10:42 · 6 min".
    static func since(_ start: Date, now: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let minutes = Int(now.timeIntervalSince(start) / 60)
        let elapsed = minutes < 1 ? "less than a minute" : "\(minutes) min"
        return "Since \(formatter.string(from: start)) · \(elapsed)"
    }

    /// "1 request" or "3 requests".
    static func count(_ count: Int, _ singular: String, _ plural: String) -> String {
        "\(count) \(count == 1 ? singular : plural)"
    }
}
