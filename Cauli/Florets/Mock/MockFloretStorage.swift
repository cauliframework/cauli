//
//  MockFloretStorage.swift
//  Cauli
//
//  Created by Cornelius Horstmann on 20.09.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import CommonCrypto
import Foundation

internal class MockFloretStorage {

    let path: URL
    let writable: Bool

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

    init(path: URL, writable: Bool) {
        self.path = path
        self.writable = writable
    }

    func store(_ record: Record) {
        guard case let .result(result) = record.result,
            let serializer = MockResponseSerializer(result) else { return }
        let path = self.path(for: record, serializer: serializer)
        try? serializer.data().write(to: path)
    }

    func mockedRecord(_ record: Record) -> Record {
        let folder = self.folder(for: record)
        let path = self.path.appendingPathComponent(folder, isDirectory: true)
        let storedResponseUrls = try? FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: [], options: [])
        if let url = storedResponseUrls?.randomElement(),
            let data = try? Data(contentsOf: url),
            let serializer = MockResponseSerializer(data) {
            let (urlResponse, data) = serializer.response()
            var record = record
            let response = Response(urlResponse, data: data)
            record.result = .result(response)
            return record
        } else if true { // instead of true we could check a "force mocking" variable
            var record = record
            let response = notFoundResponse(for: record.designatedRequest)
            record.result = .result(response)
            return record
        } else {
            return record
        }
    }

    private func notFoundResponse(for request: URLRequest) -> Response {
        let url = request.url ?? URL(string: "http://example.com")!
        let mimeType = request.value(forHTTPHeaderField: "accepts")
        let body = "<html><head></head><body><h1>404 - No Mock found</h1></body></html>".data(using: .utf8)!
        let urlResponse = URLResponse(url: url, mimeType: mimeType, expectedContentLength: body.count, textEncodingName: "utf-8")
        return Response(urlResponse, data: body)
    }

    private func path(for record: Record, serializer: MockResponseSerializer) -> URL {
        let folderName = folder(for: record)
        let fileName = serializer.filename()
        return path.appendingPathComponent(folderName, isDirectory: true).appendingPathComponent(fileName, isDirectory: false)
    }

    private func folder(for record: Record) -> String {
        return "\(record.designatedRequest.httpMethod)\(record.designatedRequest.url)".utf8.md5.description
    }
}
