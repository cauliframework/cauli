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
import OHHTTPStubsSwift
import OHHTTPStubs

class CauliURLProtocolSpec: QuickSpec {
    
    override func setUp() {
        super.setUp()
        // we are mocking everything
        stub(condition: {_ in true}) { _ in
            let stubData = "{\"response\":\"ok\"}".data(using: .utf8)
            return HTTPStubsResponse(data: stubData!, statusCode: 200, headers: ["Content-Type":"application/json"])
        }
        URLSessionConfiguration.cauliSwizzleDefaultSessionConfigurationGetter()
        URLProtocol.registerClass(CauliURLProtocol.self)
    }
    
    override func tearDown() {
        super.tearDown()
        URLProtocol.unregisterClass(CauliURLProtocol.self)
        URLSessionConfiguration.cauliSwizzleDefaultSessionConfigurationGetter()
    }
    
    override func spec() {
        describe("addDelegate") {
            it("calls the willRequest function on the delegate once a network request is performed") {
                let delegate = CauliURLProtocolDelegateStub()
                var willRequestRecord: Record?
                delegate.willRequestClosure = { record in
                    willRequestRecord = record
                }
                CauliURLProtocol.add(delegate: delegate)
                let task = URLSession.shared.dataTask(with: URL(string: "https://cauli.works")!) { (data, response, error) in }
                task.resume()
                expect(willRequestRecord).toEventuallyNot(beNil())
            }
            it("calls the didRespond function on the delegate once a network request is performed") {
                let delegate = CauliURLProtocolDelegateStub()
                var didRespondRecord: Record?
                delegate.didRespondClosure = { record in
                    didRespondRecord = record
                }
                CauliURLProtocol.add(delegate: delegate)
                let task = URLSession.shared.dataTask(with: URL(string: "https://cauli.works")!) { (data, response, error) in }
                task.resume()
                expect(didRespondRecord).toEventuallyNot(beNil())
            }
        }
        describe("removeDelegate") {
            it("stops calling the delegate functions on the delegate") {
                let delegate = CauliURLProtocolDelegateStub()
                var didCallDelegateFunction = false
                var didFinishNetworkRequest = false
                delegate.willRequestClosure = { record in
                    didCallDelegateFunction = true
                }
                delegate.didRespondClosure = { record in
                    didCallDelegateFunction = true
                }
                CauliURLProtocol.add(delegate: delegate)
                CauliURLProtocol.remove(delegate: delegate)
                let task = URLSession.shared.dataTask(with: URL(string: "https://cauli.works")!) { (data, response, error) in
                    didFinishNetworkRequest = true
                }
                task.resume()
                expect(didFinishNetworkRequest && !didCallDelegateFunction).toEventually(beTrue())
            }
        }
        describe("willRequest") {
            it("enables to change the designatedRequest") {
                let delegate = CauliURLProtocolDelegateStub()
                var didRespondRecord: Record?
                delegate.willRequestClosure = { record in
                    record.designatedRequest = URLRequest(url: URL(string: "https://cauli.works/modified")!)
                }
                delegate.didRespondClosure = { record in
                    didRespondRecord = record
                }
                
                CauliURLProtocol.add(delegate: delegate)
                let task = URLSession.shared.dataTask(with: URL(string: "https://cauli.works")!) { (data, response, error) in }
                task.resume()
                expect(didRespondRecord?.originalRequest.url?.absoluteString).toEventually(equal("https://cauli.works"))
                expect(didRespondRecord?.designatedRequest.url?.absoluteString).toEventually(equal("https://cauli.works/modified"))
                
                expect {
                    guard case let .result(response)? = didRespondRecord?.result else { return nil }
                    return response.urlResponse.url?.absoluteString
                    }.toEventually(equal("https://cauli.works/modified"))
            }
            it("enables to set the result") {
                let delegate = CauliURLProtocolDelegateStub()
                let expectedData = "spec_changed_response".data(using: .utf8)!
                var didRespondRecord: Record?
                delegate.willRequestClosure = { record in
                    let urlResponse = URLResponse(url: record.designatedRequest.url!, mimeType: nil, expectedContentLength: expectedData.count, textEncodingName: nil)
                    let response = Response(urlResponse, data: expectedData)
                    record.result = .result(response)
                }
                delegate.didRespondClosure = { record in
                    didRespondRecord = record
                }
                
                CauliURLProtocol.add(delegate: delegate)
                let task = URLSession.shared.dataTask(with: URL(string: "https://cauli.works")!) { (data, response, error) in }
                task.resume()
                expect {
                    guard case let .result(response)? = didRespondRecord?.result else { return nil }
                    return response.data
                    }.toEventually(equal(expectedData))
            }
            it("enables to set an error result") {
                let delegate = CauliURLProtocolDelegateStub()
                let expectedError = NSError(domain: "domain", code: 0, userInfo: nil)
                var didRespondRecord: Record?
                delegate.willRequestClosure = { record in
                    record.result = .error(expectedError)
                }
                delegate.didRespondClosure = { record in
                    didRespondRecord = record
                }
                
                CauliURLProtocol.add(delegate: delegate)
                let task = URLSession.shared.dataTask(with: URL(string: "https://cauli.works")!) { (data, response, error) in }
                task.resume()
                expect {
                    guard case let .error(error)? = didRespondRecord?.result else { return nil }
                    return error
                    }.toEventually(equal(expectedError))
            }
        }
        describe("didRespond") {
            it("calls with a correct result") {
                let delegate = CauliURLProtocolDelegateStub()
                var didRespondRecord: Record?
                delegate.didRespondClosure = { record in
                    didRespondRecord = record
                }
                
                CauliURLProtocol.add(delegate: delegate)
                let task = URLSession.shared.dataTask(with: URL(string: "https://cauli.works")!) { (data, response, error) in }
                task.resume()
                let expectation: Expectation<Data?> = expect {
                    guard case let .result(response)? = didRespondRecord?.result else { return nil }
                    return response.data
                    }
                expectation.toEventuallyNot(beNil())
            }
            it("enables to update the result") {
                let delegate = CauliURLProtocolDelegateStub()
                let expectedData = "spec_changed_response".data(using: .utf8)!
                var receivedData: Data?
                
                delegate.didRespondClosure = { record in
                    let urlResponse = URLResponse(url: record.designatedRequest.url!, mimeType: nil, expectedContentLength: expectedData.count, textEncodingName: nil)
                    let response = Response(urlResponse, data: expectedData)
                    record.result = .result(response)
                }
                
                CauliURLProtocol.add(delegate: delegate)
                let task = URLSession.shared.dataTask(with: URL(string: "https://cauli.works")!) { (data, response, error) in
                    receivedData = data
                }
                task.resume()
                expect(receivedData).toEventually(equal(expectedData))
            }
        }
    }
}
