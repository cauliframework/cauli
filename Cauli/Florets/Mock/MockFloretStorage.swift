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
        guard let data = MockRecordSerializer.data(for: record),
            let filename = MockFloretStorage.filename(for: record) else { return }
        let path = recordPath(for: record.designatedRequest, with: filename)
        try? FileManager.default.createDirectory(at: path.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        try? data.write(to: path)
    }

    func results(for request: URLRequest) -> [Result<Response>] {
        let path = requestPath(for: request)
        let storedResponseUrls = try? FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: [], options: [])
        return storedResponseUrls?.lazy.compactMap { url in
            if let data = try? Data(contentsOf: url),
                let record = MockRecordSerializer.record(with: data) {
                return record.result
            } else {
                return nil
            }
        } ?? []
    }

    func resultForPath(_ path: String) -> Result<Response>? {
        let absolutePath = self.path.appendingPathComponent(path, isDirectory: true)
        if let data = try? Data(contentsOf: absolutePath),
            let record = MockRecordSerializer.record(with: data) {
            return record.result
        }
        return nil
    }

    private func recordPath(for request: URLRequest, with filename: String) -> URL {
        let requestPath = self.requestPath(for: request)
        return requestPath.appendingPathComponent(filename, isDirectory: false)
    }

    private func requestPath(for request: URLRequest) -> URL {
        let foldername = MockFloretStorage.foldername(for: request)
        return path.appendingPathComponent(foldername, isDirectory: true)
    }

    private static func filename(for record: Record) -> String? {
        guard case let .result(response)? = record.result,
            let httpurlresponse = response.urlResponse as? HTTPURLResponse else {
                return nil
        }
        if let etag = httpurlresponse.allHeaderFields["ETag"] as? String {
            return MD5Digest(from: Data(etag.utf8)).description
        } else {
            let codeHash = MD5Digest(from: Data("\(httpurlresponse.statusCode)".utf8)).description
            if let data = response.data {
                let dataHash = MD5Digest(from: data).description
                return MD5Digest(from: Data("\(codeHash)\(dataHash)".utf8)).description
            } else {
                return codeHash
            }
        }
    }

    private static func foldername(for request: URLRequest) -> String {
        guard let method = request.httpMethod,
            let url = request.url else { return "unknown" }
        let regex = try! NSRegularExpression(pattern: "[^a-zA-Z0-9_]+", options: [])
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
