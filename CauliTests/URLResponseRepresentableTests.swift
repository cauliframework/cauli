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

final class URLResponseRepresentableTests: XCTestCase {

    // MARK: - init

    func testInitWithAURLResponse() {
        let fakeURLResponse = URLResponse.fake
        let urlResponseRepresentable = URLResponseRepresentable(fakeURLResponse)

        guard case .urlResponse(let urlResponse) = urlResponseRepresentable else {
            return XCTFail("expect the enum case to equal `urlResponse(URLResponse)`")
        }
        XCTAssertEqual(urlResponse, fakeURLResponse)
    }

    func testInitWithAHTTPURLResponse() {
        let fakeHTTPURLResponse = HTTPURLResponse.fake
        let urlResponseRepresentable = URLResponseRepresentable(fakeHTTPURLResponse)

        guard case .httpURLResponse(let httpURLResponse) = urlResponseRepresentable else {
            return XCTFail("expect the enum case to equal `httpURLResponse(HTTPURLResponse)`")
        }
        XCTAssertEqual(httpURLResponse.url, fakeHTTPURLResponse.url)
        XCTAssertEqual(httpURLResponse.statusCode, fakeHTTPURLResponse.statusCode)
        XCTAssertEqual(httpURLResponse.allHeaderFields["fake"] as? String, fakeHTTPURLResponse.allHeaderFields["fake"] as? String)
    }

    // MARK: - Codable

    func testDecodesAnEncodedURLResponseRepresentable() throws {
        let fakeResponseToEncode = URLResponse.fake
        let data = try JSONEncoder().encode([URLResponseRepresentable(fakeResponseToEncode)])
        let decodedValue = try JSONDecoder().decode([URLResponseRepresentable].self, from: data)

        guard let decodedURLResponseRepresentable = decodedValue.first,
            case .urlResponse(let urlResponse) = decodedURLResponseRepresentable else {
            return XCTFail("expect to decode URLResponseRepresentable from data")
        }
        XCTAssertEqual(urlResponse.url?.absoluteString, fakeResponseToEncode.url?.absoluteString)
        XCTAssertEqual(urlResponse.expectedContentLength, fakeResponseToEncode.expectedContentLength)
        XCTAssertNil(urlResponse.textEncodingName)
    }
}
