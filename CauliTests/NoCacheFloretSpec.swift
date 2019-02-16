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
import Quick
import Nimble

class NoCacheFloretSpec: QuickSpec {
    override func spec() {
        let noCacheFloret = NoCacheFloret()
        
        describe("willRequest(::") {
            it("should modify the http headers of the designatedRequest") {
                waitUntil { done in
                    var record = Record.fake()
                    record.setting(designatedRequestsHeaderFields: ["If-Modified-Since": "fake_date",
                                                                    "If-None-Match": "fake_date",
                                                                    "Cache-Control": "max-age=100"])
                    noCacheFloret.willRequest(record, modificationCompletionHandler: { (record) in
                        guard let allHTTPHeaderFields = record.designatedRequest.allHTTPHeaderFields else {
                            fail("There should be at least the Cache-Control: no-cache http header field")
                            return
                        }
                        
                        expect(allHTTPHeaderFields["Cache-Control"]) == "no-cache"
                        expect(allHTTPHeaderFields.keys.contains("If-Modified-Since")) == false
                        expect(allHTTPHeaderFields.keys.contains("If-None-Match")) == false
                        done()
                    })
                }
            }
            it("should ensure that there's at least the Cache-Control http header field") {
                waitUntil { done in
                    var record = Record.fake()
                    record.setting(designatedRequestsHeaderFields: nil)
                    noCacheFloret.willRequest(record, modificationCompletionHandler: { (record) in
                        expect(record.designatedRequest.allHTTPHeaderFields?["Cache-Control"]) == "no-cache"
                        done()
                    })
                }
            }
            it("should ensure that the request cachePolicy is reloadIgnoringLocalCacheData") {
                waitUntil { done in
                    var record = Record.fake()
                    record.setting(designatedRequestsHeaderFields: nil)
                    noCacheFloret.willRequest(record, modificationCompletionHandler: { (record) in
                        expect(record.designatedRequest.cachePolicy) == .reloadIgnoringLocalCacheData
                        done()
                    })
                }
            }
        }
        describe("didRespond(::") {
            it("should ensure that there's at least the Cache-Control http header field") {
                waitUntil { done in
                    var record = Record.fake()
                    record.setting(httpURLResponse: HTTPURLResponse(url: URL(string: "spec_fake_url")!, statusCode: 1337, httpVersion: nil, headerFields: nil)!)
                    noCacheFloret.didRespond(record, modificationCompletionHandler: { (record) in
                        guard case .result(let response)? = record.result,
                            let httpUrlResponse = response.urlResponse as? HTTPURLResponse else {
                                fail("We expect a HTTPURLResponse as result of the record")
                                return
                        }
                        
                        expect(httpUrlResponse.allHeaderFields["Cache-Control"] as? String) == "no-cache"
                        done()
                    })
                }
            }
            
            it("should modify the http headers of the httpUrlResponse") {
                waitUntil { done in
                    var record = Record.fake()
                    let httpURLResponse = HTTPURLResponse(url: URL(string: "spec_fake_url")!,
                                                          statusCode: 1337,
                                                          httpVersion: nil,
                                                          headerFields: ["Last-Modified": "fake_date",
                                                                         "Expires": "100",
                                                                         "ETag": "1337",
                                                                         "Cache-Control": "max-age=100"])!
                    record.setting(httpURLResponse: httpURLResponse)
                    noCacheFloret.didRespond(record, modificationCompletionHandler: { (record) in
                        guard case .result(let response)? = record.result,
                            let httpUrlResponse = response.urlResponse as? HTTPURLResponse else {
                                fail("We expect a HTTPURLResponse as result of the record")
                                return
                        }
                        
                        expect(httpUrlResponse.allHeaderFields["Cache-Control"] as? String) == "no-cache"
                        expect(httpUrlResponse.allHeaderFields["Expires"] as? String) == "0"
                        expect(httpUrlResponse.allHeaderFields.keys.contains("ETag")) == false
                        expect(httpUrlResponse.allHeaderFields.keys.contains("Last-Modified")) == false
                        done()
                    })
                }
            }
        }
    }
}

