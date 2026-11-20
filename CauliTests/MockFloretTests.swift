//
//  Copyright (c) 2026 cauli.works
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
import Foundation
import XCTest

final class MockFloretTests: XCTestCase {

    private let url = URL(string: "https://cauli.works/mocked")!
    private let mockedData = Data(#"{"mocked": true}"#.utf8)
    private var mockFolder: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        // A folder outside of the app bundle, like a folder on the Mac when running in the simulator.
        mockFolder = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("MockFloretTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: mockFolder, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: mockFolder)
        mockFolder = nil
        try super.tearDownWithError()
    }

    // MARK: - mockFolder

    func testMocksRequestsWithResponsesFromTheMockFolder() throws {
        try recordResponse(for: URLRequest(url: url))
        let floret = MockFloret(mode: .mock(forced: false), mockFolder: mockFolder)

        let record = waitForCompletion { floret.willRequest(Record(URLRequest(url: url)), modificationCompletionHandler: $0) }

        guard case .result(let response)? = record?.result else {
            return XCTFail("expected the request to be answered with the recorded response")
        }
        XCTAssertEqual(response.data, mockedData)
        XCTAssertEqual((response.urlResponse as? HTTPURLResponse)?.statusCode, 200)
    }

    func testDoesNotMockRequestsWithoutAResponseInTheMockFolder() throws {
        try recordResponse(for: URLRequest(url: url))
        let floret = MockFloret(mode: .mock(forced: false), mockFolder: mockFolder)
        let otherRequest = URLRequest(url: URL(string: "https://cauli.works/not-mocked")!)

        let record = waitForCompletion { floret.willRequest(Record(otherRequest), modificationCompletionHandler: $0) }

        XCTAssertNotNil(record)
        XCTAssertNil(record?.result)
    }

    func testResultForPathIsRelativeToTheMockFolder() throws {
        let recordedPath = try recordResponse(for: URLRequest(url: url))
        let floret = MockFloret(mode: .mock(forced: false), mockFolder: mockFolder)

        guard case .result(let response)? = floret.resultForPath(recordedPath) else {
            return XCTFail("expected a result for the path \(recordedPath)")
        }
        XCTAssertEqual(response.data, mockedData)
    }

    // MARK: - Helper

    /// Records a response for the request into the mock folder, like the `.record` mode does.
    ///
    /// - Returns: The path of the recorded response, relative to the mock folder.
    @discardableResult
    private func recordResponse(for request: URLRequest) throws -> String {
        let httpResponse = try XCTUnwrap(HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"]))
        var record = Record(request)
        record.result = .result(Response(httpResponse, data: mockedData))
        MockFloretStorage(path: mockFolder, writable: true).store(record)

        let requestFolders = try FileManager.default.contentsOfDirectory(atPath: mockFolder.path)
        let requestFolder = try XCTUnwrap(requestFolders.first, "the record should have been stored in the mock folder")
        let responseFolders = try FileManager.default.contentsOfDirectory(atPath: mockFolder.appendingPathComponent(requestFolder).path)
        let responseFolder = try XCTUnwrap(responseFolders.first)
        return "\(requestFolder)/\(responseFolder)"
    }
}
