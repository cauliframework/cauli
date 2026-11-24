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

/// Colors and texts of the security audit screens.
internal enum SecurityAuditFormatting {

    /// The text color of a severity, readable on the cell background and on its badge in light and dark mode.
    static func color(of severity: SecurityAuditSeverity) -> UIColor {
        switch severity {
        case .critical: return dynamic(light: (0.702, 0.149, 0.118), dark: (1, 0.412, 0.380))
        case .warning: return dynamic(light: (0.541, 0.271, 0), dark: (1, 0.702, 0.251))
        case .info: return dynamic(light: (0.039, 0.333, 0.710), dark: (0.561, 0.757, 1))
        }
    }

    /// The badge background of a severity.
    static func badgeColor(of severity: SecurityAuditSeverity) -> UIColor {
        color(of: severity).withAlphaComponent(0.14)
    }

    /// E.g. "GET api.example.com/feed · 38×" or "2 endpoints · 60×".
    static func details(of issue: SecurityAuditIssue) -> String {
        let place = issue.endpoints.count == 1 ? issue.endpoints[0].name : "\(issue.endpoints.count) \(issue.example.scope == .host ? "hosts" : "endpoints")"
        return "\(place) · \(issue.count)×"
    }

    /// E.g. "38 requests · last at 09:52".
    static func details(of endpoint: SecurityAuditIssue.Endpoint) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = Calendar.current.isDateInToday(endpoint.lastSeen) ? .none : .short
        formatter.timeStyle = .short
        return "\(endpoint.count) \(endpoint.count == 1 ? "request" : "requests") · last at \(formatter.string(from: endpoint.lastSeen))"
    }

    private static func dynamic(light: (CGFloat, CGFloat, CGFloat), dark: (CGFloat, CGFloat, CGFloat)) -> UIColor {
        UIColor { traits in
            let rgb = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1)
        }
    }
}
