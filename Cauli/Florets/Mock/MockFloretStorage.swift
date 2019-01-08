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
        guard case .result(let response)? = record.result,
            let responseFoldername = MockFloretStorage.foldername(for: response) else { return }
        let requestFoldername = MockFloretStorage.foldername(for: record.designatedRequest)
        let requestPath = path.appendingPathComponent(requestFoldername, isDirectory: true)
        let storedResponseUrls = (try? FileManager.default.contentsOfDirectory(atPath: requestPath.path)) ?? []
        if storedResponseUrls.contains(where: { $0.starts(with: responseFoldername) }) {
            // already recorded
            return
        }
        if let tempRecordPath = MockRecordSerializer.write(record: record) {
            let responsePath = requestPath.appendingPathComponent(responseFoldername, isDirectory: true)
            try? FileManager.default.createDirectory(at: requestPath, withIntermediateDirectories: true, attributes: nil)
            try? FileManager.default.moveItem(at: tempRecordPath, to: responsePath)
        }
    }

    func results(for request: URLRequest) -> [Result<Response>] {
        let requestFoldername = MockFloretStorage.foldername(for: request)
        let requestPath = path.appendingPathComponent(requestFoldername, isDirectory: true)
        let storedResponseUrls = try? FileManager.default.contentsOfDirectory(at: requestPath, includingPropertiesForKeys: [], options: [])
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

    private static func foldername(for response: Response) -> String? {
        guard let httpurlresponse = response.urlResponse as? HTTPURLResponse else {
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
            let url = request.url,
            let regex = try? NSRegularExpression(pattern: "[^a-zA-Z0-9_]+", options: []) else { return "unknown" }

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
