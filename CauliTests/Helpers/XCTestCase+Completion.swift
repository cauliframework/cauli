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
import XCTest

extension XCTestCase {
    /// Calls `operation` with a completion handler and waits until that handler was called.
    ///
    /// - Returns: The record passed to the completion handler, or `nil` if it wasn't called in time.
    @discardableResult
    func waitForCompletion(timeout: TimeInterval = 1, _ operation: (@escaping (Record) -> Void) -> Void) -> Record? {
        let completionCalled = expectation(description: "completion handler called")
        var receivedRecord: Record?
        operation { record in
            receivedRecord = record
            completionCalled.fulfill()
        }
        wait(for: [completionCalled], timeout: timeout)
        return receivedRecord
    }
}
