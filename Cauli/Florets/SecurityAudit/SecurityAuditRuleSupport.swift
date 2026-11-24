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

/// Helpers of the built-in rules.
internal enum SecurityAuditRuleSupport {

    /// The credential of a header value, e.g. the token of "Bearer eyJh…", or the whole value.
    static func credential(in value: String) -> String {
        let parts = value.split(separator: " ", maxSplits: 1)
        let schemes = ["bearer", "basic", "digest", "token"]
        if parts.count == 2, let scheme = parts.first, schemes.contains(scheme.lowercased()) {
            return String(parts[1])
        }
        return value
    }

    /// The values of the URL's query, masked in the evidence in case they hold something private.
    static func queryValues(of url: URL) -> [String] {
        (URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []).compactMap(\.value).filter { $0.count >= 6 }
    }
}
