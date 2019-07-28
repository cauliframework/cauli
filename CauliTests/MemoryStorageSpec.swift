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

class MemoryStorageSpec: QuickSpec {
    override func spec() {
        describe("init") {
            it("should initialize with the correct capacity") {
                let storage = MemoryStorage(capacity: .records(10))
                expect(storage.capacity) == .records(10)
            }
        }
        describe("store") {
            it("should store the item in the records") {
                let storage = MemoryStorage(capacity: .records(10))
                let record = Record.fake()
                storage.store(record)
                expect(storage.records.count) == 1
                expect(storage.records.first?.identifier) == record.identifier
            }
            it("should replace an existing record with the same uuid") {
                let storage = MemoryStorage(capacity: .records(10))
                let record = Record.fake()
                storage.store(record)
                let updatedUrl = URL(string: "spec_modified_url")!
                let modifiedRecord = record.setting(requestUrl: updatedUrl)
                storage.store(modifiedRecord)
                expect(storage.records.count) == 1
                expect(storage.records.first?.request.url) == updatedUrl
            }
            it("should remove the oldest record if the limit is exceeded") {
                let storage = MemoryStorage(capacity: .records(1))
                let firstRecord = Record.fake()
                storage.store(firstRecord)
                let secondRecord = Record.fake()
                storage.store(secondRecord)
                expect(storage.records.count) == 1
                expect(storage.records.first?.identifier) == secondRecord.identifier
            }
        }
        describe("records:after:") {
            it("should return the newest items") {
                let storage = MemoryStorage(capacity: .records(10))
                let firstRecord = Record.fake()
                let secondRecord = Record.fake()
                storage.store(firstRecord)
                storage.store(secondRecord)
                expect(storage.records.count) == 2
                expect(storage.records(limit: 1, after: nil).first!.identifier) == secondRecord.identifier
            }
            it("should not fail if more items requested than existing") {
                let storage = MemoryStorage(capacity: .records(10))
                let firstRecord = Record.fake()
                storage.store(firstRecord)
                expect(storage.records(limit: 10, after: nil).count) == 1
            }
            it("should only return the amount of items requested") {
                let storage = MemoryStorage(capacity: .records(10))
                let firstRecord = Record.fake()
                let secondRecord = Record.fake()
                storage.store(firstRecord)
                storage.store(secondRecord)
                expect(storage.records.count) == 2
                expect(storage.records(limit: 1, after: nil).count) == 1
            }
            it("should not return the after-item") {
                let storage = MemoryStorage(capacity: .records(10))
                let firstRecord = Record.fake()
                let secondRecord = Record.fake()
                storage.store(firstRecord)
                storage.store(secondRecord)
                expect(storage.records.count) == 2
                expect(storage.records(limit: 1, after: secondRecord).count) == 1
                expect(storage.records(limit: 1, after: secondRecord).first!.identifier) == firstRecord.identifier
            }
            it("should return no item if the after-item is the last") {
                let storage = MemoryStorage(capacity: .records(10))
                let firstRecord = Record.fake()
                storage.store(firstRecord)
                expect(storage.records(limit: 10, after: firstRecord).count) == 0
            }
        }
        describe("preStorageRecordModifier") {
            it("should return a modifier record") {
                let headerKey = "fake"
                let recordModifier = RecordModifier(keyPath: \Record.request) { designatedRequest -> (URLRequest) in
                    var request = designatedRequest
                    request.setValue(String(repeating: "*", count: (request.value(forHTTPHeaderField: headerKey) ?? "").count), forHTTPHeaderField: headerKey)
                    return request
                }
                let storage = MemoryStorage(capacity: .records(10), preStorageRecordModifier: recordModifier)
                var firstRecord = Record.fake()
                firstRecord.setting(requestsHeaderFields: [headerKey: "fake"])
                storage.store(firstRecord)
                expect(storage.records(limit: 1, after: nil).first!.request.value(forHTTPHeaderField: headerKey)) != firstRecord.request.value(forHTTPHeaderField: headerKey)
                expect(storage.records(limit: 1, after: nil).first!.request.value(forHTTPHeaderField: headerKey)) == "****"
            }
        }
    }
}
