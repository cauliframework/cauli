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

final class NoCacheFloretTests: XCTestCase {

    private let noCacheFloret = NoCacheFloret()

    // MARK: - willRequest

    func testWillRequestModifiesTheHTTPHeadersOfTheDesignatedRequest() {
        var record = Record.fake()
        record.setting(designatedRequestsHeaderFields: ["If-Modified-Since": "fake_date",
                                                        "If-None-Match": "fake_date",
                                                        "Cache-Control": "max-age=100"])
        let modifiedRecord = waitForCompletion { noCacheFloret.willRequest(record, modificationCompletionHandler: $0) }

        guard let allHTTPHeaderFields = modifiedRecord?.designatedRequest.allHTTPHeaderFields else {
            return XCTFail("There should be at least the Cache-Control: no-cache http header field")
        }
        XCTAssertEqual(allHTTPHeaderFields["Cache-Control"], "no-cache")
        XCTAssertFalse(allHTTPHeaderFields.keys.contains("If-Modified-Since"))
        XCTAssertFalse(allHTTPHeaderFields.keys.contains("If-None-Match"))
    }

    func testWillRequestEnsuresThatThereIsACacheControlHTTPHeaderField() {
        var record = Record.fake()
        record.setting(designatedRequestsHeaderFields: nil)
        let modifiedRecord = waitForCompletion { noCacheFloret.willRequest(record, modificationCompletionHandler: $0) }
        XCTAssertEqual(modifiedRecord?.designatedRequest.allHTTPHeaderFields?["Cache-Control"], "no-cache")
    }

    func testWillRequestSetsTheCachePolicyToReloadIgnoringLocalCacheData() {
        var record = Record.fake()
        record.setting(designatedRequestsHeaderFields: nil)
        let modifiedRecord = waitForCompletion { noCacheFloret.willRequest(record, modificationCompletionHandler: $0) }
        XCTAssertEqual(modifiedRecord?.designatedRequest.cachePolicy, .reloadIgnoringLocalCacheData)
    }

    // MARK: - didRespond

    func testDidRespondEnsuresThatThereIsACacheControlHTTPHeaderField() {
        var record = Record.fake()
        record.setting(httpURLResponse: HTTPURLResponse(url: URL(string: "spec_fake_url")!, statusCode: 1337, httpVersion: nil, headerFields: nil)!)
        let modifiedRecord = waitForCompletion { noCacheFloret.didRespond(record, modificationCompletionHandler: $0) }

        guard case .result(let response)? = modifiedRecord?.result,
            let httpUrlResponse = response.urlResponse as? HTTPURLResponse else {
            return XCTFail("We expect a HTTPURLResponse as result of the record")
        }
        XCTAssertEqual(httpUrlResponse.allHeaderFields["Cache-Control"] as? String, "no-cache")
    }

    func testDidRespondModifiesTheHTTPHeadersOfTheHTTPURLResponse() {
        var record = Record.fake()
        let httpURLResponse = HTTPURLResponse(url: URL(string: "spec_fake_url")!,
                                              statusCode: 1337,
                                              httpVersion: nil,
                                              headerFields: ["Last-Modified": "fake_date",
                                                             "Expires": "100",
                                                             "ETag": "1337",
                                                             "Cache-Control": "max-age=100"])!
        record.setting(httpURLResponse: httpURLResponse)
        let modifiedRecord = waitForCompletion { noCacheFloret.didRespond(record, modificationCompletionHandler: $0) }

        guard case .result(let response)? = modifiedRecord?.result,
            let httpUrlResponse = response.urlResponse as? HTTPURLResponse else {
            return XCTFail("We expect a HTTPURLResponse as result of the record")
        }
        XCTAssertEqual(httpUrlResponse.allHeaderFields["Cache-Control"] as? String, "no-cache")
        XCTAssertEqual(httpUrlResponse.allHeaderFields["Expires"] as? String, "0")
        XCTAssertFalse(httpUrlResponse.allHeaderFields.keys.contains("ETag"))
        XCTAssertFalse(httpUrlResponse.allHeaderFields.keys.contains("Last-Modified"))
    }
}
