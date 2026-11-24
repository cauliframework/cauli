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

/// The findings of a rule with the same title, grouped by endpoint, as the `SecurityAuditFloret` shows them.
public struct SecurityAuditIssue: Equatable {

    /// An endpoint or host with the problem.
    public struct Endpoint: Equatable {
        /// E.g. "GET api.example.com/users/:id", or a host if the finding's scope is `.host`.
        public let name: String
        /// How many requests had the problem.
        public let count: Int
        /// When the problem was found last.
        public let lastSeen: Date
    }

    /// Identifies the issue: its rule and title.
    public let identifier: String

    /// The most serious severity of its findings.
    public let severity: SecurityAuditSeverity

    /// The endpoints, most requests first.
    public let endpoints: [Endpoint]

    /// The most recent finding, e.g. for its summary and evidence.
    public let example: SecurityAuditFinding

    /// The title, e.g. "Secrets in URLs".
    public var title: String {
        example.title
    }

    /// How many requests had the problem.
    public var count: Int {
        endpoints.reduce(0) { $0 + $1.count }
    }
}

/// A finding that is ignored for an endpoint, kept across app starts.
public struct SecurityAuditIgnoredFinding: Codable, Equatable {
    /// The identifier of the issue.
    public let issueIdentifier: String
    /// The title of the issue, e.g. "Cleartext HTTP".
    public let title: String
    /// The name of the endpoint, e.g. "GET 192.168.1.20:8080/api/:id".
    public let endpoint: String
}
