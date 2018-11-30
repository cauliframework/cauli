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

@testable import Cauli
import Foundation
import Quick
import Nimble

class URLResponseRepresentableSpec: QuickSpec {
    
    override func spec() {
        describe("init") {
            it("should initialize with a URLResponse") {
                let fakeURLResponse = URLResponse.fake
                let urlResponseRepresentable: URLResponseRepresentable = URLResponseRepresentable(fakeURLResponse)
                
                guard case .urlResponse(let urlResponse) = urlResponseRepresentable else {
                    fail("expect the enum case to equal `urlResponse(URLResponse)`")
                    return
                }
                
                expect(urlResponse) == fakeURLResponse
            }
            
            it("should initialize with a HTTPURLResponse") {
                let urlResponseRepresentable = URLResponseRepresentable(HTTPURLResponse.fake)
                
                expect({
                    guard case .httpURLResponse(let httpURLResponse) = urlResponseRepresentable else {
                        return .failed(reason: "expect the enum case to equal `httpURLResponse(HTTPURLResponse)`")
                    }
                    
                    expect(httpURLResponse.url?.absoluteString) == "https://cauli.works/fake"
                    expect(httpURLResponse.statusCode) == 200
                    expect(httpURLResponse.allHeaderFields["fake"] as? String) == "fake"
                    
                    return .succeeded
                }).to(succeed())
            }
        }
        
        describe("codable") {
            it("decode iOS10 JSON encoded data as httpURLResponse", closure: {
                let expectedResponse = HTTPURLResponse(url: URL(string: "https://cauli.works/fake")!,
                                                       statusCode: 200,
                                                       httpVersion: nil,
                                                       headerFields: ["fake": "fake"])
                
                // The JSON encoded data is an array with a single URLRessponseRepresentable ([URLRessponseRepresentable]),
                // since the JSONEncoder cannot encode Top-level objects. (https://bugs.swift.org/browse/SR-6163)
                let decodedData = self.data(for: "iOS10_jsonEncoded_URLResponseRepresentable_case_httpURLResponse")
                guard let data = decodedData else {
                    fail("could not read decodedData from file: iOS10_jsonEncoded_URLResponseRepresentable_case_httpURLResponse")
                    return
                }
                
                guard let decodedValue = try? JSONDecoder().decode([URLResponseRepresentable].self, from: data),
                    let urlResponseRepresentable = decodedValue.first,
                    case .httpURLResponse(let httpURLResponse) = urlResponseRepresentable else {
                        fail("could not decode URLResponseRepresentable from decodedData")
                        return
                }
                
                expect(httpURLResponse.url) == expectedResponse?.url
                expect(httpURLResponse.statusCode) == expectedResponse?.statusCode
                expect(httpURLResponse.allHeaderFields["fake"] as? String) == expectedResponse?.allHeaderFields["fake"] as? String
            })
            
            it("should decode an encoded URLResponseRepresentable", closure: {
                let fakeResponseToEncode = URLResponse.fake
                let urlResponseRepresentable = URLResponseRepresentable(fakeResponseToEncode)
                let encodedData: Data? = try? JSONEncoder().encode([urlResponseRepresentable])
                
                guard let data = encodedData else {
                    fail("encodedData is nil")
                    return
                }
                
                guard let decodedValue = try? JSONDecoder().decode([URLResponseRepresentable].self, from: data),
                    let decodedURLResponseRepresentable = decodedValue.first,
                    case .urlResponse(let urlResponse) = decodedURLResponseRepresentable else {
                        fail("expect to decode URLResponseRepresentable from data")
                        return
                }
                
                expect(urlResponse.url?.absoluteString) == fakeResponseToEncode.url?.absoluteString
                expect(urlResponse.expectedContentLength) == fakeResponseToEncode.expectedContentLength
                expect(urlResponse.textEncodingName).to(beNil())
            })
        }
    }
    
    private func data(for fileName: String) -> Data? {
        guard let path = Bundle(for: type(of: self)).path(forResource: fileName, ofType: nil),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        
        return data
    }
    
}
