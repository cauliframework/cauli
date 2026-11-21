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

final class BodyPreviewTests: XCTestCase {

    func testCompactsJSONAndKeepsTheKeyOrder() {
        let json = """
        {
          "zebra" : 1,
          "data" : {
            "name" : "Cauli",
            "roles" : [ "admin", "dev" ]
          }
        }
        """

        XCTAssertEqual(BodyPreview.preview(of: Data(json.utf8)), #"{"zebra":1,"data":{"name":"Cauli","roles":["admin","dev"]}}"#)
    }

    func testKeepsWhitespaceAndEscapedQuotesInsideJSONStrings() {
        let json = #"[ { "quote" : "He said \"hello  world\" " } ]"#

        XCTAssertEqual(BodyPreview.preview(of: Data(json.utf8)), #"[{"quote":"He said \"hello  world\" "}]"#)
    }

    func testCollapsesWhitespaceOfOtherText() {
        let html = "<html>\n  <body>\n    <h1>Hello\tCauli</h1>\n  </body>\n</html>\n"

        XCTAssertEqual(BodyPreview.preview(of: Data(html.utf8)), "<html> <body> <h1>Hello Cauli</h1> </body> </html>")
    }

    func testHasNoPreviewForBinaryData() {
        XCTAssertNil(BodyPreview.preview(of: Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10])))
    }

    func testHasNoPreviewForAnEmptyOrMissingBody() {
        XCTAssertNil(BodyPreview.preview(of: nil))
        XCTAssertNil(BodyPreview.preview(of: Data()))
        XCTAssertNil(BodyPreview.preview(of: Data(" \n ".utf8)))
    }

    func testTruncatesLongPreviews() throws {
        let text = String(repeating: "a", count: BodyPreview.maximumLength + 10)

        let preview = try XCTUnwrap(BodyPreview.preview(of: Data(text.utf8)))

        XCTAssertEqual(preview, String(repeating: "a", count: BodyPreview.maximumLength) + "…")
    }

    func testOnlyLooksAtTheBeginningOfLargeBodies() throws {
        // "ä" is two bytes, so the inspected prefix ends in the middle of a character.
        let text = "x" + String(repeating: "ä", count: BodyPreview.inspectedByteCount)

        let preview = try XCTUnwrap(BodyPreview.preview(of: Data(text.utf8)), "a cut multi-byte character must not prevent the preview")

        XCTAssertTrue(preview.hasPrefix("xää"))
        XCTAssertTrue(preview.hasSuffix("…"))
    }

    // MARK: - Record details

    func testTheBodyRowShowsTheSizeAndThePreview() {
        let body = Data(#"{ "ip" : "77.11.38.000" }"#.utf8)
        var request = URLRequest(url: URL(string: "https://cauli.works")!)
        request.httpMethod = "POST"
        request.httpBody = body

        let item = RecordTableViewDatasource.Section(request).items.first { $0.title == "Body" }

        XCTAssertEqual(item?.description, "\(body.count) bytes\n" + #"{"ip":"77.11.38.000"}"#)
        XCTAssertEqual(item?.numberOfLines, 6)
    }

    func testTheBodyRowOnlyShowsTheSizeOfBinaryData() {
        let response = Response(HTTPURLResponse(url: URL(string: "https://cauli.works/image.jpg")!, statusCode: 200, httpVersion: nil, headerFields: nil)!, data: Data([0xFF, 0xD8, 0xFF]))

        XCTAssertEqual(RecordTableViewDatasource.Item.forBody(in: response).description, "3 bytes")
    }
}
