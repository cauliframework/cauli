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

/// Finds e-mail addresses and phone numbers in URLs and header values.
internal enum PersonalDataDetector {

    struct Match: Equatable {
        /// E.g. "e-mail address".
        let kind: String
        let value: String
    }

    // swiftlint:disable:next force_try
    private static let email = try! NSRegularExpression(pattern: "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}", options: [.caseInsensitive])
    private static let phoneParameterNames: Set<String> = ["phone", "phonenumber", "phone_number", "mobile", "tel", "msisdn"]

    /// The e-mail addresses and phone numbers in the path and query of the URL.
    static func matches(in url: URL) -> [Match] {
        var matches = url.pathComponents.flatMap(emails(in:))
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        for item in items {
            guard let value = item.value, !value.isEmpty else { continue }
            matches += emails(in: value)
            if isPhoneNumber(value, parameter: item.name) {
                matches.append(Match(kind: "phone number", value: value))
            }
        }
        return unique(matches)
    }

    /// The e-mail addresses in the text, e.g. a header value.
    static func emails(in text: String) -> [Match] {
        let range = NSRange(text.startIndex..., in: text)
        return email.matches(in: text, range: range).compactMap { result in
            Range(result.range, in: text).map { Match(kind: "e-mail address", value: String(text[$0])) }
        }
    }

    /// Whether the text, e.g. a path segment, contains an e-mail address.
    static func containsPersonalData(_ text: String) -> Bool {
        let decoded = text.removingPercentEncoding ?? text
        return !emails(in: decoded).isEmpty
    }

    /// A value of a parameter named like a phone number, or an international number like "+49 170 1234567".
    static func isPhoneNumber(_ value: String, parameter: String) -> Bool {
        let digits = value.filter(\.isNumber).count
        let allowed = CharacterSet(charactersIn: "+0123456789 ()-./")
        guard value.unicodeScalars.allSatisfy(allowed.contains) else { return false }
        if phoneParameterNames.contains(parameter.lowercased()) {
            return digits >= 6
        }
        return value.hasPrefix("+") && (8...15).contains(digits)
    }

    /// E.g. "An e-mail address", "A phone number" or "E-mail addresses and phone numbers".
    static func describe(_ matches: [Match]) -> String {
        if matches.count == 1, let kind = matches.first?.kind {
            return (kind == "e-mail address" ? "An " : "A ") + kind
        }
        let kinds = ["e-mail address", "phone number"].filter { kind in matches.contains { $0.kind == kind } }
        let text = kinds.map { $0 + ($0.hasSuffix("s") ? "es" : "s") }.joined(separator: " and ")
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    private static func unique(_ matches: [Match]) -> [Match] {
        matches.reduce(into: [Match]()) { if !$0.contains($1) { $0.append($1) } }
    }
}
