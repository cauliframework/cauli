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

/// One request the `NetworkUsageFloret` recorded: what was requested and how it was transferred.
public struct NetworkUsageTransfer: Codable, Equatable {

    /// When the response was received.
    public var date: Date

    /// The HTTP method, e.g. "GET".
    public var method: String

    /// The url of the request, without its fragment.
    public var url: String

    /// The host of the request, e.g. "api.example.com".
    public var host: String

    /// The path with ids replaced by `:id`, e.g. "/users/:id" for "/users/42".
    public var endpoint: String

    /// The status code of the response, `nil` for a non-HTTP response.
    public var statusCode: Int?

    /// The `Content-Type` of the response, without parameters, e.g. "application/json".
    public var responseContentType: String?

    /// The `Content-Encoding` of the response, e.g. "gzip". `nil` if the response wasn't compressed.
    public var responseContentEncoding: String?

    /// The `Content-Encoding` of the request body, `nil` if it wasn't compressed.
    public var requestContentEncoding: String?

    /// `true` if the response allows caching or revalidating it: a `Cache-Control` without
    /// `no-store`, an `ETag` or a `Last-Modified` header field.
    public var isCacheable: Bool

    /// The bytes, cache, protocol and duration of the transfer.
    public var metrics: TransferMetrics

    /// Creates a transfer with the given values, e.g. for tests of custom rules.
    public init(date: Date, method: String, url: String, host: String, endpoint: String, statusCode: Int?, responseContentType: String?, responseContentEncoding: String?, requestContentEncoding: String?, isCacheable: Bool, metrics: TransferMetrics) {
        self.date = date
        self.method = method
        self.url = url
        self.host = host
        self.endpoint = endpoint
        self.statusCode = statusCode
        self.responseContentType = responseContentType
        self.responseContentEncoding = responseContentEncoding
        self.requestContentEncoding = requestContentEncoding
        self.isCacheable = isCacheable
        self.metrics = metrics
    }

    /// Identifies the endpoint across requests, e.g. "GET api.example.com/users/:id".
    public var endpointKey: String {
        "\(method) \(host)\(endpoint)"
    }

    /// `true` if the response body was compressed for the transfer.
    public var isResponseCompressed: Bool {
        NetworkUsageTransfer.isCompressed(responseContentEncoding)
    }

    /// `true` if the request body was compressed for the transfer.
    public var isRequestCompressed: Bool {
        NetworkUsageTransfer.isCompressed(requestContentEncoding)
    }
}

extension NetworkUsageTransfer {
    /// Creates the transfer of a record. `nil` if the record has no metrics, e.g. because a floret
    /// set its result, or if its request has no url with a host.
    init?(_ record: Record, date: Date = Date()) {
        guard let metrics = record.metrics,
            let url = record.designatedRequest.url,
            let host = url.host else { return nil }
        let response = record.result.flatMap { result -> HTTPURLResponse? in
            guard case let .result(response) = result else { return nil }
            return response.urlResponse as? HTTPURLResponse
        }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.fragment = nil
        let cacheControl = response?.value(forHeaderField: "Cache-Control")?.lowercased()
        let allowsCaching = cacheControl.map { !$0.contains("no-store") } ?? false
        self.init(
            date: date,
            method: record.designatedRequest.httpMethod ?? "GET",
            url: components?.string ?? url.absoluteString,
            host: host,
            endpoint: EndpointPattern.pattern(for: url.path),
            statusCode: response?.statusCode,
            responseContentType: response?.value(forHeaderField: "Content-Type").map(NetworkUsageTransfer.mediaType),
            responseContentEncoding: response?.value(forHeaderField: "Content-Encoding"),
            requestContentEncoding: record.designatedRequest.value(forHTTPHeaderField: "Content-Encoding"),
            isCacheable: allowsCaching || response?.value(forHeaderField: "ETag") != nil || response?.value(forHeaderField: "Last-Modified") != nil,
            metrics: metrics
        )
    }

    /// "application/json; charset=utf-8" becomes "application/json".
    static func mediaType(_ contentType: String) -> String {
        contentType.split(separator: ";").first.map { $0.trimmingCharacters(in: .whitespaces).lowercased() } ?? ""
    }

    static func isCompressed(_ contentEncoding: String?) -> Bool {
        guard let encoding = contentEncoding?.trimmingCharacters(in: .whitespaces).lowercased() else { return false }
        return !encoding.isEmpty && encoding != "identity"
    }
}

internal extension HTTPURLResponse {
    /// The value of a header field, independent of the case of its name.
    func value(forHeaderField name: String) -> String? {
        allHeaderFields.first { ($0.key as? String)?.caseInsensitiveCompare(name) == .orderedSame }?.value as? String
    }
}
