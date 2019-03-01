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

import Foundation

internal final class MemoryStorage: Storage {

    var records: [Record] = []
    var capacity: StorageCapacity {
        didSet {
            ensureCapacity()
        }
    }
    var preStorageRecordModifier: RecordModifier?

    init(capacity: StorageCapacity, preStorageRecordModifier: RecordModifier? = nil) {
        self.capacity = capacity
        self.preStorageRecordModifier = preStorageRecordModifier
    }

    func store(_ record: Record) {
        assert(Thread.isMainThread, "\(#file):\(#line) must run on the main thread!")
        let modifiedRecord = preStorageRecordModifier?.modify(record) ?? record
        if let recordIndex = records.index(where: { $0.identifier == modifiedRecord.identifier }) {
            records[recordIndex] = modifiedRecord
        } else {
            records.insert(modifiedRecord, at: 0)
            ensureCapacity()
        }
    }

    func records(_ count: Int, after record: Record?) -> [Record] {
        assert(Thread.isMainThread, "\(#file):\(#line) must run on the main thread!")
        let index: Int
        if let record = record,
            let recordIndex = records.index(where: { $0.identifier == record.identifier }) {
            index = recordIndex + 1
        } else {
            index = 0
        }
        let maxCount = min(count, records.count - index)
        return Array(records[index..<(index + maxCount)])
    }

    private func ensureCapacity() {
        switch capacity {
        case .unlimited: return
        case .records(let maximumRecordCount):
            records = Array(records.prefix(maximumRecordCount))
        }
    }
}
