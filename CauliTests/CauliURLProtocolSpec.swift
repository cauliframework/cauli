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

class CauliURLProtocolSpec: QuickSpec {
    
    let mocker = CauliURLProtocolDelegateMocker()
    
    override func setUp() {
        super.setUp()
        CauliURLProtocol.add(delegate: mocker)
        URLSessionConfiguration.cauliSwizzleDefaultSessionConfigurationGetter()
        URLProtocol.registerClass(CauliURLProtocol.self)
    }
    
    override func tearDown() {
        super.tearDown()
        CauliURLProtocol.remove(delegate: mocker)
        URLProtocol.unregisterClass(CauliURLProtocol.self)
        URLSessionConfiguration.cauliSwizzleDefaultSessionConfigurationGetter()
    }
    
    // TODO: add a mocking delegate/floret for all these requests
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
            // I am not to sure about this spec
            // In the end it is just testing the mocked delegate
            // I am not sure what would be the best way to test this implementation
            // and have a mocked response (since we don't want to rely on the network)
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
                // The mocker has do be added after the tested delegate
                // otherwise it will not use the changed url
                CauliURLProtocol.remove(delegate: self.mocker)
                CauliURLProtocol.add(delegate: self.mocker)
                let task = URLSession.shared.dataTask(with: URL(string: "https://cauli.works")!) { (data, response, error) in }
                task.resume()
                expect(didRespondRecord?.originalRequest.url?.absoluteString).toEventually(equal("https://cauli.works"))
                expect(didRespondRecord?.designatedRequest.url?.absoluteString).toEventually(equal("https://cauli.works/modified"))
                if case let .result(response)? = didRespondRecord?.result {
                    expect(response.urlResponse.url?.absoluteString) == "https://cauli.works/modified"
                } else {
                    fail("Expected a result")
                }
            }
            it("enables to set the result") {}
            it("enables to set an error result") {}
        }
        describe("didRespond") {
            it("calls with a correct result") {}
            it("enables to update the result") {}
        }
    }
}
