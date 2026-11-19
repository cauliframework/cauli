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
import Foundation
import XCTest

final class HTTPBodyStreamFloretTests: XCTestCase {

    private let url = URL(string: "https://cauli.works/upload")!

    func testConvertsAStreamWithinTheLimitIntoAHTTPBody() {
        let body = Data(repeating: 7, count: 10 * 1024)
        let floret = HTTPBodyStreamFloret(maximumConvertedByteSize: 50 * 1024)

        let record = waitForCompletion { floret.willRequest(Record(request(withBodyStream: InputStream(data: body))), modificationCompletionHandler: $0) }

        XCTAssertEqual(record?.designatedRequest.httpBody, body)
        XCTAssertNil(record?.designatedRequest.httpBodyStream)
    }

    // MARK: - Regression: streams larger than the limit

    func testKeepsTheCompleteBodyOfAStreamLargerThanTheLimit() {
        let body = Data(repeating: 7, count: 100 * 1024)
        let floret = HTTPBodyStreamFloret(maximumConvertedByteSize: 50 * 1024)

        let record = waitForCompletion { floret.willRequest(Record(request(withBodyStream: InputStream(data: body))), modificationCompletionHandler: $0) }

        XCTAssertEqual(record.map(bodyData(of:)), body, "the request must still be sent with its complete body")
        if let record = record {
            waitForCompletion { floret.didRespond(record, modificationCompletionHandler: $0) }
        }
    }

    func testRemovesTheTemporaryBodyFileOnceTheResponseArrived() throws {
        let body = Data(repeating: 7, count: 100 * 1024)
        let floret = HTTPBodyStreamFloret(maximumConvertedByteSize: 50 * 1024)
        let existingFiles = try temporaryBodyFiles()

        let record = try XCTUnwrap(waitForCompletion { floret.willRequest(Record(request(withBodyStream: InputStream(data: body))), modificationCompletionHandler: $0) })
        let createdFiles = try temporaryBodyFiles().subtracting(existingFiles)
        XCTAssertEqual(createdFiles.count, 1, "a body above the limit is expected to be kept in a temporary file")

        waitForCompletion { floret.didRespond(record, modificationCompletionHandler: $0) }

        XCTAssertTrue(try temporaryBodyFiles().isDisjoint(with: createdFiles), "the temporary file should be removed")
    }

    // MARK: - Regression: streams that fail while reading

    func testDoesNotCrashWhenTheStreamFailsWhileReading() {
        let floret = HTTPBodyStreamFloret()

        // `read` returns -1, which must not be used as a byte count.
        let record = waitForCompletion { floret.willRequest(Record(request(withBodyStream: FailingInputStream())), modificationCompletionHandler: $0) }

        XCTAssertNotNil(record)
        XCTAssertNil(record?.designatedRequest.httpBody, "a failed read must not produce a body")
    }

    // MARK: - Helper

    private func temporaryBodyFiles() throws -> Set<String> {
        Set(try FileManager.default.contentsOfDirectory(atPath: NSTemporaryDirectory()).filter { $0.hasPrefix("cauli-httpbody-") })
    }

    private func request(withBodyStream stream: InputStream) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBodyStream = stream
        return request
    }

    /// The body that would be sent: the `httpBody`, or whatever is left to read from the `httpBodyStream`.
    private func bodyData(of record: Record) -> Data {
        if let body = record.designatedRequest.httpBody {
            return body
        }
        guard let stream = record.designatedRequest.httpBodyStream else { return Data() }
        var data = Data()
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        stream.open()
        defer { stream.close() }
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            guard read > 0 else { break }
            data.append(buffer, count: read)
        }
        return data
    }
}
