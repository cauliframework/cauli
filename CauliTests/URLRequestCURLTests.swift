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

final class URLRequestCURLTests: XCTestCase {

    private let url = URL(string: "https://cauli.works/fake")!

    func testContainsTheMethodAndURL() {
        let request = URLRequest(url: url)

        XCTAssertEqual(request.cURLCommand, """
        curl \\
          -X GET \\
          https://cauli.works/fake
        """)
    }

    func testAddsEveryHeaderFieldAsSeparateArgument() {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/xml", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        XCTAssertEqual(request.cURLCommand, """
        curl \\
          -X POST \\
          -H 'Accept: application/json' \\
          -H 'Content-Type: text/xml' \\
          https://cauli.works/fake
        """)
    }

    func testAddsATextBody() {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data(#"{ "http": "body" }"#.utf8)

        XCTAssertEqual(request.cURLCommand, """
        curl \\
          -X POST \\
          --data-binary '{ "http": "body" }' \\
          https://cauli.works/fake
        """)
    }

    func testQuotesValuesSoTheShellDoesntInterpretThem() {
        var request = URLRequest(url: URL(string: "https://cauli.works/fake?a=1&b=$HOME")!)
        request.httpMethod = "POST"
        request.setValue("it's", forHTTPHeaderField: "X-Quote")
        request.httpBody = Data("$(rm -rf ~) `whoami` 'quoted'".utf8)

        XCTAssertEqual(request.cURLCommand, """
        curl \\
          -X POST \\
          -H 'X-Quote: it'\\''s' \\
          --data-binary '$(rm -rf ~) `whoami` '\\''quoted'\\''' \\
          'https://cauli.works/fake?a=1&b=$HOME'
        """)
    }

    func testMentionsABinaryBodyInsteadOfAddingIt() {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = Data([0xFF, 0x00, 0xFE])

        XCTAssertEqual(request.cURLCommand, """
        curl \\
          -X PUT \\
          https://cauli.works/fake
        # The binary body of 3 bytes is not included.
        """)
    }

    func testMentionsABodyStreamInsteadOfAddingIt() {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBodyStream = InputStream(data: Data("streamed".utf8))

        XCTAssertEqual(request.cURLCommand, """
        curl \\
          -X POST \\
          https://cauli.works/fake
        # The body stream is not included.
        """)
    }

    // MARK: - Record detail

    func testTheRecordDetailsContainTheCURLCommand() throws {
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let section = RecordTableViewDatasource.Section(request)
        let item = try XCTUnwrap(section.items.first { $0.title == "cURL" })

        XCTAssertEqual(item.description, request.cURLCommand)
        XCTAssertEqual(item.value?() as? String, request.cURLCommand)
    }
}
