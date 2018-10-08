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
    
    override func setUp() {
        super.setUp()
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
                    return record
                }
                CauliURLProtocol.add(delegate: delegate)
                let task = URLSession.shared.dataTask(with: URL(string: "https://cauli.works")!) { (data, response, error) in }
                task.resume()
                expect(willRequestRecord).toEventuallyNot(beNil())
            }
            it("calls the didRespomd function on the delegate once a network request is performed") {
                let delegate = CauliURLProtocolDelegateStub()
                var didRespondRecord: Record?
                delegate.didRespondClosure = { record in
                    didRespondRecord = record
                    return record
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
                    return record
                }
                delegate.didRespondClosure = { record in
                    didCallDelegateFunction = true
                    return record
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
            it("uses the original and designated request") {}
            it("enables to change the designatedRequest") {}
            it("enables to set the result") {}
            it("enables to set an error result") {}
        }
        describe("didRespond") {
            // I think for this we should use an additional mocking delegate/floret
            it("calls with a correct result") {}
            it("enables to update the result") {}
        }
    }
}
