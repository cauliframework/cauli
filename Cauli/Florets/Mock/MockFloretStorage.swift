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
        guard let data = MockRecordSerializer.data(for: record) else { return }
        let filename = MockFloretStorage.filename(for: data)
        let path = recordPath(for: record, with: filename)
        try? data.write(to: path)
    }

    func mockedRecord(_ record: Record) -> Record? {
        let path = requestPath(for: record)
        let storedResponseUrls = try? FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: [], options: [])
        if let url = storedResponseUrls?.randomElement(),
            let data = try? Data(contentsOf: url) {
            var record = record
            record.result = MockRecordSerializer.record(with: data)?.result ?? .none
            return record
        } else {
            return nil
        }
    }

    private func recordPath(for record: Record, with filename: String) -> URL {
        let requestPath = self.requestPath(for: record)
        return requestPath.appendingPathComponent(filename, isDirectory: false)
    }

    private func requestPath(for record: Record) -> URL {
        let foldername = MockFloretStorage.foldername(for: record)
        return path.appendingPathComponent(foldername, isDirectory: true)
    }

    private static func filename(for data: Data) -> String {
        return data.md5.description
    }

    private static func foldername(for record: Record) -> String {
        guard let method = record.designatedRequest.httpMethod,
            let url = record.designatedRequest.url else { return "unknown" }
        return "\(method)\(url)".utf8.md5.description
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
