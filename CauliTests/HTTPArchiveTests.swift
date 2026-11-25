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

@testable import Cauliframework
import UIKit
import XCTest

final class HTTPArchiveTests: XCTestCase {

    func testIsAHAR12Log() throws {
        let log = try XCTUnwrap(try archive([record()])["log"] as? [String: Any])
        XCTAssertEqual(log["version"] as? String, "1.2")
        XCTAssertEqual((log["creator"] as? [String: Any])?["name"] as? String, "Cauli")
        XCTAssertEqual((log["entries"] as? [Any])?.count, 1)
    }

    func testTheRequest() throws {
        let request = try XCTUnwrap(try entries([record()]).first?["request"] as? [String: Any])
        XCTAssertEqual(request["method"] as? String, "POST")
        XCTAssertEqual(request["url"] as? String, "https://api.example.com/users?page=2&q=jane%20doe")
        XCTAssertEqual(request["httpVersion"] as? String, "HTTP/2")
        XCTAssertEqual(pairs(request["queryString"]), ["page=2", "q=jane doe"])
        XCTAssertEqual(pairs(request["headers"]), ["Content-Type=application/json", "Cookie=session=abc; theme=dark"])
        XCTAssertEqual(pairs(request["cookies"]), ["session=abc", "theme=dark"])
        XCTAssertEqual(request["headersSize"] as? Int, 300)
        XCTAssertEqual(request["bodySize"] as? Int, 15)
        let postData = try XCTUnwrap(request["postData"] as? [String: Any])
        XCTAssertEqual(postData["mimeType"] as? String, "application/json")
        XCTAssertEqual(postData["text"] as? String, "{\"name\":\"Jane\"}")
    }

    func testTheResponse() throws {
        let entry = try XCTUnwrap(try entries([record()]).first)
        let response = try XCTUnwrap(entry["response"] as? [String: Any])
        XCTAssertEqual(response["status"] as? Int, 201)
        XCTAssertEqual(response["statusText"] as? String, HTTPURLResponse.localizedString(forStatusCode: 201))
        XCTAssertEqual(response["redirectURL"] as? String, "https://api.example.com/users/42")
        XCTAssertEqual(response["headersSize"] as? Int, 200)
        XCTAssertEqual(response["bodySize"] as? Int, 10)
        let cookie = try XCTUnwrap((response["cookies"] as? [[String: Any]])?.first)
        XCTAssertEqual(cookie["name"] as? String, "session")
        XCTAssertEqual(cookie["httpOnly"] as? Bool, true)
        let content = try XCTUnwrap(response["content"] as? [String: Any])
        XCTAssertEqual(content["text"] as? String, "{\"id\":42}")
        XCTAssertEqual(content["size"] as? Int, 9)
        XCTAssertEqual(content["mimeType"] as? String, "application/json")
        XCTAssertNil(content["compression"], "the body wasn't compressed")

        XCTAssertEqual(entry["time"] as? Double ?? 0, 250, accuracy: 0.001)
        XCTAssertEqual(entry["startedDateTime"] as? String, "2026-11-25T08:00:00.500Z")
        XCTAssertEqual((entry["timings"] as? [String: Any])?["wait"] as? Double ?? 0, 250, accuracy: 0.001)
        XCTAssertEqual(entry["_tlsVersion"] as? String, "TLS 1.3")
    }

    func testBinaryBodiesAreBase64() throws {
        let png = Data([0x89, 0x50, 0x4E, 0x47, 0xFF, 0xFE])
        let content = try XCTUnwrap(try entries([record(responseBody: png, contentType: "image/png")]).first.flatMap { ($0["response"] as? [String: Any])?["content"] as? [String: Any] })
        XCTAssertEqual(content["encoding"] as? String, "base64")
        XCTAssertEqual(content["text"] as? String, png.base64EncodedString())
    }

    func testAFailedRequestHasStatusZeroAndItsError() throws {
        var failed = record()
        failed.result = .error(NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: [NSLocalizedDescriptionKey: "The request timed out."]))
        let response = try XCTUnwrap(try entries([failed]).first?["response"] as? [String: Any])
        XCTAssertEqual(response["status"] as? Int, 0)
        XCTAssertEqual(response["_error"] as? String, "The request timed out. (NSURLErrorDomain -1001)")
    }

    func testEntriesAreSortedByTheirStart() throws {
        var later = record(url: "https://api.example.com/later")
        later.requestStarted = Date(timeIntervalSince1970: 2_000)
        var earlier = record(url: "https://api.example.com/earlier")
        earlier.requestStarted = Date(timeIntervalSince1970: 1_000)
        let urls = try entries([later, earlier]).compactMap { ($0["request"] as? [String: Any])?["url"] as? String }
        XCTAssertEqual(urls, ["https://api.example.com/earlier", "https://api.example.com/later"])
    }

    func testHTTPVersions() {
        var record = self.record()
        for (name, version) in [("h2", "HTTP/2"), ("h3", "HTTP/3"), ("http/1.1", "HTTP/1.1")] {
            record.metrics?.networkProtocol = name
            XCTAssertEqual(HTTPArchive.httpVersion(of: record), version)
        }
        record.metrics = nil
        XCTAssertEqual(HTTPArchive.httpVersion(of: record), "unknown")
    }

    func testSharingWritesAHARFile() throws {
        let url = try HTTPArchiveSharing.fileURL(for: [record()], at: Date(timeIntervalSince1970: 0))
        defer { try? FileManager.default.removeItem(at: url) }
        XCTAssertEqual(url.pathExtension, "har")
        XCTAssertTrue(url.lastPathComponent.hasPrefix("cauli-"))
        let object = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
        XCTAssertNotNil(object?["log"])
    }

    // MARK: - Helper

    private func record(url: String = "https://api.example.com/users?page=2&q=jane%20doe", responseBody: Data = Data("{\"id\":42}".utf8), contentType: String = "application/json") -> Record {
        let requestURL = URL(string: url)!
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("session=abc; theme=dark", forHTTPHeaderField: "Cookie")
        request.httpBody = Data("{\"name\":\"Jane\"}".utf8)
        var record = Record(request)
        let headers = ["Content-Type": contentType, "Location": "https://api.example.com/users/42", "Set-Cookie": "session=xyz; Path=/; HttpOnly; Secure"]
        let response = HTTPURLResponse(url: requestURL, statusCode: 201, httpVersion: "HTTP/2", headerFields: headers)!
        record.result = .result(Response(response, data: responseBody))
        record.requestStarted = Date(timeIntervalSince1970: 1_795_593_600.5)
        record.responseReceived = record.requestStarted?.addingTimeInterval(0.3)
        record.metrics = TransferMetrics(requestHeaderBytes: 300, requestBodyBytes: 15, responseHeaderBytes: 200, responseBodyBytes: 10, responseBodyBytesDecoded: 9, isFromCache: false, networkProtocol: "h2", isReusedConnection: true, duration: 0.25, tlsVersion: "TLS 1.3")
        return record
    }

    private func archive(_ records: [Record]) throws -> [String: Any] {
        let object = try JSONSerialization.jsonObject(with: HTTPArchive.data(for: records))
        return try XCTUnwrap(object as? [String: Any])
    }

    private func entries(_ records: [Record]) throws -> [[String: Any]] {
        let log = try XCTUnwrap(try archive(records)["log"] as? [String: Any])
        return try XCTUnwrap(log["entries"] as? [[String: Any]])
    }

    /// E.g. ["page=2"] for [{"name": "page", "value": "2"}].
    private func pairs(_ value: Any?) -> [String] {
        (value as? [[String: Any]] ?? []).map { "\($0["name"] as? String ?? "")=\($0["value"] as? String ?? "")" }
    }
}

final class HTTPArchiveSharingTests: XCTestCase {

    private final class CapturingInspectorTableViewController: InspectorTableViewController {
        var presentedControllers: [UIViewController] = []

        override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
            presentedControllers.append(viewControllerToPresent)
        }
    }

    func testTheListSharesAllOrTheMatchingRequests() throws {
        let cauli = Cauli([], configuration: Configuration(recordSelector: .all(), enableShakeGesture: false, storageCapacity: .unlimited))
        for path in ["users", "users/42", "config"] {
            cauli.storage.store(Record(URLRequest(url: URL(string: "https://api.example.com/\(path)")!)))
        }
        let sut = CapturingInspectorTableViewController(cauli, formatter: InspectorFloretFormatter())
        sut.loadViewIfNeeded()
        XCTAssertTrue(sut.navigationItem.rightBarButtonItem === sut.shareButton)

        sut.dataSource.filterString = "users"
        XCTAssertEqual(sut.recordsToShare(matchingSearch: false).count, 3)
        XCTAssertEqual(sut.recordsToShare(matchingSearch: true).count, 2)

        sut.shareButtonTapped()
        let actionSheet = try XCTUnwrap(sut.presentedControllers.last as? UIAlertController)
        XCTAssertEqual(actionSheet.actions.map(\.title), ["All Requests (3)", "Matching “users” (2)", "Cancel"])
        assertIsAnchoredToTheShareButton(actionSheet, of: sut)

        sut.share(sut.recordsToShare(matchingSearch: true))
        let shareSheet = try XCTUnwrap(sut.presentedControllers.last as? UIActivityViewController)
        assertIsAnchoredToTheShareButton(shareSheet, of: sut)
    }

    /// On iPad, sheets are presented as popovers and need an anchor. On iPhone, they have no popover.
    private func assertIsAnchoredToTheShareButton(_ sheet: UIViewController, of sut: InspectorTableViewController, line: UInt = #line) {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        XCTAssertTrue(sheet.popoverPresentationController?.barButtonItem === sut.shareButton, line: line)
    }
}
