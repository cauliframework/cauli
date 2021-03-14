//
//  Copyright (c) 2021 cauli.works
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

class URLRequestCURLSpec: QuickSpec {
    
    override func spec() {
        describe("cURL") {
            it("returns a curl command with http method and URL") {
                let fakeRequest = URLRequest.fake()
                expect(fakeRequest.cURL) == "curl -X GET https://cauli.works/fake"
            }
            
            it("starts with curl as prefix") {
                let fakeRequest = URLRequest.fake()
                let hasCurlAsPrefix = fakeRequest.cURL.hasPrefix("curl")
                expect(hasCurlAsPrefix) == true
            }
            
            it("returns a curl command matching the request URL") {
                let fakeRequest = URLRequest.fake()
                let hasURLasSuffix = fakeRequest.cURL.hasSuffix("https://cauli.works/fake")
                expect(hasURLasSuffix) == true
            }
            
            it("ensures to contain the request http method") {
                let httpMethod = "POST"
                let fakeRequest = URLRequest.fake(httpMethod: httpMethod)
                let containsRequestMethodPost = fakeRequest.cURL.contains("-X \(httpMethod)")
                expect(containsRequestMethodPost) == true
            }
            
            it("ensures to contain the http header fields") {
                let httpHeaders = ["Accept": "application/json", "Content-Type": "text/xml"]
                let fakeRequest = URLRequest.fake(httpHeaders: httpHeaders)
                let containsAcceptHTTPHeader = fakeRequest.cURL.contains("-H \"Accept: application/json\"")
                let containsContentTypeHTTPHeader = fakeRequest.cURL.contains("-H \"Content-Type: text/xml\"")
                expect(containsAcceptHTTPHeader && containsContentTypeHTTPHeader) == true
            }
            
            it("ensures to contain the http body data") {
                let httpBody = "{ \"http\": \"body\" }"
                let fakeRequest = URLRequest.fake(httpBody: httpBody)
                let containsHttpBody = fakeRequest.cURL.contains("-d \"\(httpBody)\"")
                expect(containsHttpBody) == true
            }
        }
    }
    
}
