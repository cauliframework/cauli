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

final class MemoryStorageTests: XCTestCase {

    // MARK: - init

    func testInitUsesTheCorrectCapacity() {
        let storage = MemoryStorage(capacity: .records(10))
        XCTAssertEqual(storage.capacity, .records(10))
    }

    // MARK: - store

    func testStoreAddsTheItemToTheRecords() {
        let storage = MemoryStorage(capacity: .records(10))
        let record = Record.fake()
        storage.store(record)
        XCTAssertEqual(storage.records.count, 1)
        XCTAssertEqual(storage.records.first?.identifier, record.identifier)
    }

    func testStoreReplacesAnExistingRecordWithTheSameIdentifier() {
        let storage = MemoryStorage(capacity: .records(10))
        let record = Record.fake()
        storage.store(record)
        let updatedUrl = URL(string: "spec_modified_url")!
        storage.store(record.setting(originalRequestUrl: updatedUrl))
        XCTAssertEqual(storage.records.count, 1)
        XCTAssertEqual(storage.records.first?.originalRequest.url, updatedUrl)
    }

    func testStoreRemovesTheOldestRecordIfTheLimitIsExceeded() {
        let storage = MemoryStorage(capacity: .records(1))
        storage.store(Record.fake())
        let secondRecord = Record.fake()
        storage.store(secondRecord)
        XCTAssertEqual(storage.records.count, 1)
        XCTAssertEqual(storage.records.first?.identifier, secondRecord.identifier)
    }

    // MARK: - records(_:after:)

    func testRecordsReturnsTheNewestItems() {
        let storage = MemoryStorage(capacity: .records(10))
        let secondRecord = Record.fake()
        storage.store(Record.fake())
        storage.store(secondRecord)
        XCTAssertEqual(storage.records.count, 2)
        XCTAssertEqual(storage.records(1, after: nil).first?.identifier, secondRecord.identifier)
    }

    func testRecordsDoesNotFailIfMoreItemsAreRequestedThanExisting() {
        let storage = MemoryStorage(capacity: .records(10))
        storage.store(Record.fake())
        XCTAssertEqual(storage.records(10, after: nil).count, 1)
    }

    func testRecordsOnlyReturnsTheAmountOfItemsRequested() {
        let storage = MemoryStorage(capacity: .records(10))
        storage.store(Record.fake())
        storage.store(Record.fake())
        XCTAssertEqual(storage.records.count, 2)
        XCTAssertEqual(storage.records(1, after: nil).count, 1)
    }

    func testRecordsDoesNotReturnTheAfterItem() {
        let storage = MemoryStorage(capacity: .records(10))
        let firstRecord = Record.fake()
        let secondRecord = Record.fake()
        storage.store(firstRecord)
        storage.store(secondRecord)
        XCTAssertEqual(storage.records.count, 2)
        XCTAssertEqual(storage.records(1, after: secondRecord).count, 1)
        XCTAssertEqual(storage.records(1, after: secondRecord).first?.identifier, firstRecord.identifier)
    }

    func testRecordsReturnsNoItemIfTheAfterItemIsTheLast() {
        let storage = MemoryStorage(capacity: .records(10))
        let firstRecord = Record.fake()
        storage.store(firstRecord)
        XCTAssertEqual(storage.records(10, after: firstRecord).count, 0)
    }

    // MARK: - preStorageRecordModifier

    func testPreStorageRecordModifierModifiesTheStoredRecord() {
        let headerKey = "fake"
        let recordModifier = RecordModifier(keyPath: \Record.designatedRequest) { designatedRequest -> (URLRequest) in
            var request = designatedRequest
            request.setValue(String(repeating: "*", count: (request.value(forHTTPHeaderField: headerKey) ?? "").count), forHTTPHeaderField: headerKey)
            return request
        }
        let storage = MemoryStorage(capacity: .records(10), preStorageRecordModifier: recordModifier)
        var firstRecord = Record.fake()
        firstRecord.setting(designatedRequestsHeaderFields: [headerKey: "fake"])
        storage.store(firstRecord)

        let storedHeaderValue = storage.records(1, after: nil).first?.designatedRequest.value(forHTTPHeaderField: headerKey)
        XCTAssertNotEqual(storedHeaderValue, firstRecord.designatedRequest.value(forHTTPHeaderField: headerKey))
        XCTAssertEqual(storedHeaderValue, "****")
    }
}
