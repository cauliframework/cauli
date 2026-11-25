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

/// Turns records into an HTTP Archive (HAR 1.2), which Chrome DevTools, Firefox, Charles, Proxyman
/// and other tools can open.
///
/// ```swift
/// let data = try HTTPArchive.data(for: records)
/// try data.write(to: fileURL)
/// ```
///
/// A HAR file contains the full requests and responses, including tokens and cookies.
/// Failed requests have the status 0 and the error in the `_error` field of their response.
public enum HTTPArchive {

    /// The HAR JSON of the records, sorted by the time their request started.
    public static func data(for records: [Record]) throws -> Data {
        try JSONSerialization.data(withJSONObject: object(for: records), options: [.prettyPrinted, .sortedKeys])
    }

    /// The HAR object of the records, sorted by the time their request started.
    static func object(for records: [Record]) -> [String: Any] {
        let sorted = records.enumerated().sorted { lhs, rhs in
            let lhsDate = startDate(of: lhs.element)
            let rhsDate = startDate(of: rhs.element)
            return lhsDate == rhsDate ? lhs.offset < rhs.offset : lhsDate < rhsDate
        }
        let info = Bundle.main.infoDictionary ?? [:]
        let app = [info["CFBundleName"], info["CFBundleShortVersionString"]].compactMap { $0 as? String }.joined(separator: " ")
        return ["log": [
            "version": "1.2",
            "creator": ["name": "Cauli", "version": ""],
            "comment": app.isEmpty ? "Exported by Cauli" : "Exported by Cauli from \(app)",
            "entries": sorted.map { entry(for: $0.element) }
        ]]
    }

    static func entry(for record: Record) -> [String: Any] {
        let time = duration(of: record) * 1_000
        var entry: [String: Any] = [
            "startedDateTime": dateFormatter.string(from: startDate(of: record)),
            "time": time,
            "request": request(of: record),
            "response": response(of: record),
            "cache": [String: Any](),
            "timings": ["blocked": -1, "dns": -1, "connect": -1, "ssl": -1, "send": 0, "wait": time, "receive": 0]
        ]
        if let metrics = record.metrics {
            entry["_fromCache"] = metrics.isFromCache
            if let tlsVersion = metrics.tlsVersion {
                entry["_tlsVersion"] = tlsVersion
            }
        }
        return entry
    }

    // MARK: - Request

    private static func request(of record: Record) -> [String: Any] {
        let request = record.designatedRequest
        let url = request.url
        let headers = request.allHTTPHeaderFields ?? [:]
        let queryItems = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems } ?? []
        var object: [String: Any] = [
            "method": request.httpMethod ?? "GET",
            "url": url?.absoluteString ?? "",
            "httpVersion": httpVersion(of: record),
            "cookies": requestCookies(from: headers),
            "headers": nameValuePairs(headers),
            "queryString": queryItems.map { ["name": $0.name, "value": $0.value ?? ""] },
            "headersSize": record.metrics?.requestHeaderBytes ?? -1,
            "bodySize": request.httpBody?.count ?? (request.httpBodyStream == nil ? 0 : -1)
        ]
        if let body = request.httpBody, !body.isEmpty {
            var postData = text(of: body)
            postData["mimeType"] = header("Content-Type", in: headers) ?? ""
            if postData["encoding"] != nil {
                postData["_encoding"] = postData.removeValue(forKey: "encoding")
            }
            object["postData"] = postData
        }
        return object
    }

    private static func requestCookies(from headers: [String: String]) -> [[String: Any]] {
        guard let cookie = header("Cookie", in: headers) else { return [] }
        return cookie.split(separator: ";").compactMap { pair in
            let parts = pair.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard let name = parts.first, !name.isEmpty else { return nil }
            return ["name": name, "value": parts.count > 1 ? parts[1] : ""]
        }
    }

    // MARK: - Response

    private static func response(of record: Record) -> [String: Any] {
        switch record.result {
        case .result(let response)?:
            return self.response(response, of: record)
        case .error(let error)?:
            return failedResponse(error: "\(error.localizedDescription) (\(error.domain) \(error.code))")
        case nil:
            return failedResponse(error: "No response")
        }
    }

    private static func response(_ response: Response, of record: Record) -> [String: Any] {
        let httpResponse = response.urlResponse as? HTTPURLResponse
        let headers = (httpResponse?.allHeaderFields as? [String: String]) ?? [:]
        let body = response.data ?? Data()
        var content = body.isEmpty ? [String: Any]() : text(of: body)
        content["size"] = body.count
        content["mimeType"] = header("Content-Type", in: headers) ?? response.urlResponse.mimeType ?? "x-unknown"
        let metrics = record.metrics
        if let metrics = metrics, metrics.responseBodyBytesDecoded > metrics.responseBodyBytes, metrics.responseBodyBytes > 0 {
            content["compression"] = metrics.responseBodyBytesDecoded - metrics.responseBodyBytes
        }
        let statusCode = httpResponse?.statusCode ?? 0
        let bodySize: Int64
        if let metrics = metrics {
            bodySize = metrics.isFromCache ? 0 : metrics.responseBodyBytes
        } else {
            bodySize = Int64(body.count)
        }
        return [
            "status": statusCode,
            "statusText": httpResponse.map { HTTPURLResponse.localizedString(forStatusCode: $0.statusCode) } ?? "",
            "httpVersion": httpVersion(of: record),
            "cookies": responseCookies(from: headers, url: response.urlResponse.url),
            "headers": nameValuePairs(headers),
            "content": content,
            "redirectURL": header("Location", in: headers) ?? "",
            "headersSize": metrics.map { $0.isFromCache ? -1 : $0.responseHeaderBytes } ?? -1,
            "bodySize": bodySize
        ]
    }

    private static func failedResponse(error: String) -> [String: Any] {
        [
            "status": 0,
            "statusText": "",
            "httpVersion": "",
            "cookies": [Any](),
            "headers": [Any](),
            "content": ["size": 0, "mimeType": "x-unknown"],
            "redirectURL": "",
            "headersSize": -1,
            "bodySize": -1,
            "_error": error
        ]
    }

    private static func responseCookies(from headers: [String: String], url: URL?) -> [[String: Any]] {
        guard let url = url else { return [] }
        return HTTPCookie.cookies(withResponseHeaderFields: headers, for: url).map { cookie in
            var object: [String: Any] = [
                "name": cookie.name,
                "value": cookie.value,
                "path": cookie.path,
                "domain": cookie.domain,
                "httpOnly": cookie.isHTTPOnly,
                "secure": cookie.isSecure
            ]
            if let expires = cookie.expiresDate {
                object["expires"] = dateFormatter.string(from: expires)
            }
            return object
        }
    }

    // MARK: - Helpers

    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static func startDate(of record: Record) -> Date {
        record.requestStarted ?? record.responseReceived ?? Date(timeIntervalSince1970: 0)
    }

    /// In seconds: the transfer duration from the metrics, else the time between the request and the response.
    private static func duration(of record: Record) -> TimeInterval {
        if let duration = record.metrics?.duration {
            return duration
        }
        guard let start = record.requestStarted, let end = record.responseReceived else { return 0 }
        return max(0, end.timeIntervalSince(start))
    }

    /// E.g. "HTTP/2" for "h2", as `TransferMetrics.networkProtocol` names it.
    static func httpVersion(of record: Record) -> String {
        switch record.metrics?.networkProtocol?.lowercased() {
        case "h2"?: return "HTTP/2"
        case "h3"?, "hq"?: return "HTTP/3"
        case "http/1.1"?: return "HTTP/1.1"
        case "http/1.0"?: return "HTTP/1.0"
        case let other?: return other.uppercased()
        case nil: return "unknown"
        }
    }

    /// The body as UTF-8 text, else base64.
    private static func text(of data: Data) -> [String: Any] {
        if let text = String(data: data, encoding: .utf8) {
            return ["text": text]
        }
        return ["text": data.base64EncodedString(), "encoding": "base64"]
    }

    private static func nameValuePairs(_ headers: [String: String]) -> [[String: Any]] {
        headers.sorted { $0.key.lowercased() < $1.key.lowercased() }.map { ["name": $0.key, "value": $0.value] }
    }

    private static func header(_ name: String, in headers: [String: String]) -> String? {
        headers.first { $0.key.caseInsensitiveCompare(name) == .orderedSame }?.value
    }
}
