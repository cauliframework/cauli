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

internal class MockFloretStorage {

    let path: URL
    let writable: Bool

    private init(path: URL, writable: Bool) {
        self.path = path
        self.writable = writable
    }

    func store(_ record: Record) {
        guard case .result(let response)? = record.result else { return }
        let requestFoldername = MockFloretStorage.foldername(for: record.designatedRequest)
        let responseFoldername = MockFloretStorage.foldername(for: response)
        let folder = path
            .appendingPathComponent(requestFoldername, isDirectory: true)
            .appendingPathComponent(responseFoldername, isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
        MockRecordSerializer.write(record: record, to: folder)
    }

    func results(for request: URLRequest) -> [Result<Response>] {
        let path = requestPath(for: request)
        let storedResponseUrls = try? FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: [], options: [])
        return storedResponseUrls?.lazy.compactMap { url in
            MockRecordSerializer.record(from: url)?.result
        } ?? []
    }

    func resultForPath(_ path: String) -> Result<Response>? {
        let absolutePath = self.path.appendingPathComponent(path, isDirectory: true)
        if let record = MockRecordSerializer.record(from: absolutePath) {
            return record.result
        }
        return nil
    }

    private func requestPath(for request: URLRequest) -> URL {
        let foldername = MockFloretStorage.foldername(for: request)
        return path.appendingPathComponent(foldername, isDirectory: true)
    }

    private static func foldername(for response: Response) -> String {
        if let httpurlresponse = response.urlResponse as? HTTPURLResponse,
            let etag = httpurlresponse.allHeaderFields["ETag"] as? String {
            return etag.utf8.md5.description
        } else {
            let statuscodePrefix: String
            if let httpurlresponse = response.urlResponse as? HTTPURLResponse {
                statuscodePrefix = "\(httpurlresponse.statusCode)"
            } else {
                statuscodePrefix = ""
            }
            if let data = response.data {
                let dataHash = data.md5.description
                return "\(statuscodePrefix)\(dataHash)".utf8.md5.description
            } else {
                return "empty"
            }
        }
    }

    private static func foldername(for request: URLRequest) -> String {
        guard let method = request.httpMethod,
            let url = request.url else { return "unknown" }

        // swiftlint:disable force_try
        let regex = try! NSRegularExpression(pattern: "[^a-zA-Z0-9_]+", options: [])
        // swiftlint:enable force_try

        let foldername = "\(method)_\(url)"
        return regex.stringByReplacingMatches(in: foldername, options: [], range: NSRange(location: 0, length: foldername.count), withTemplate: "_")
    }
}

extension MockFloretStorage {

    static func recorder() -> MockFloretStorage {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let documentsUrl = URL(fileURLWithPath: documentsPath)
        let recorderPath = documentsUrl.appendingPathComponent("MockFloret")
        try? FileManager.default.createDirectory(at: recorderPath, withIntermediateDirectories: true, attributes: nil)
        return MockFloretStorage(path: recorderPath, writable: true)
    }

    static func mocker() -> MockFloretStorage? {
        guard let url = Bundle.main.resourceURL?.appendingPathComponent("MockFloret", isDirectory: true) else { return nil }
        return MockFloretStorage(path: url, writable: false)
    }
}
