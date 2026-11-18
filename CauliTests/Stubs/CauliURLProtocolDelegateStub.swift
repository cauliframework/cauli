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

class CauliURLProtocolDelegateStub: CauliURLProtocolDelegate {
    /// Decides whether a record is handled. Defaults to handling every record.
    var handlesClosure: ((Record) -> Bool)?
    var willRequestClosure: ((inout Record) -> Void)?
    var didRespondClosure: ((inout Record) -> Void)?
    /// Takes over `willRequest` completely, e.g. to call the completion handler later.
    var willRequestHandler: ((Record, @escaping (Record) -> Void) -> Void)?

    func handles(_ record: Record) -> Bool {
        handlesClosure?(record) ?? true
    }

    func willRequest(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        if let willRequestHandler = willRequestHandler {
            willRequestHandler(record, completionHandler)
        } else if let willRequestClosure = willRequestClosure {
            var updatedRecord = record
            willRequestClosure(&updatedRecord)
            completionHandler(updatedRecord)
        } else {
            completionHandler(record)
        }
    }

    func didRespond(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        if let didRespondClosure = didRespondClosure {
            var updatedRecord = record
            didRespondClosure(&updatedRecord)
            completionHandler(updatedRecord)
        } else {
            completionHandler(record)
        }
    }
}
