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

internal final class HybridStorage: Storage {

    let path: URL
    var records: [SwappedRecord] = []

    var capacity: StorageCapacity = .unlimited {
        didSet {
            ensureCapacity()
        }
    }

    var preStorageRecordModifier: RecordModifier?

    init(path: URL) {
        try? FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
        self.path = path
        records = readRecords(from: path)
    }

    func store(_ record: Record) {
        try? remove(record: record)
        let recordFolderPath = path.appendingPathComponent(record.identifier.uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: recordFolderPath, withIntermediateDirectories: true, attributes: nil)
        let swappedRecord = record.swapped(to: recordFolderPath)
        records.insert(swappedRecord, at: 0)
        ensureCapacity()
        write(records, to: path)
    }

    func records(_ count: Int, after record: Record?) -> [Record] {
        let basePath = path
        return swappedRecords(count, after: record).compactMap { swappedRecord in
            let recordFolderPath = basePath.appendingPathComponent(swappedRecord.identifier.uuidString, isDirectory: true)
            return swappedRecord.record(in: recordFolderPath)
        }
    }

    private func swappedRecords(_ count: Int, after record: Record?) -> [SwappedRecord] {
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

    private func remove(record: Record) throws {
        try removeRecordByIdentifier(record.identifier)
    }

    private func removeRecordByIdentifier(_ identifier: UUID) throws {
        guard records.contains(where: { $0.identifier == identifier }) else { return }
        let recordFolderPath = path.appendingPathComponent(identifier.uuidString, isDirectory: true)
        try FileManager.default.removeItem(at: recordFolderPath)
        records = records.filter { $0.identifier != identifier }
    }

    private func ensureCapacity() {
        switch capacity {
        case .unlimited: return
        case .records(let maximumRecordCount):
            let recordsToDelete = Array(records.suffix(max(0, records.count - maximumRecordCount)))
            for record in recordsToDelete {
                try? removeRecordByIdentifier(record.identifier)
            }
            records = Array(records.prefix(maximumRecordCount))
        }
    }

}

// Write to disk
extension HybridStorage {

    static let metadataFilename = "HybridStorage.metadata.json"

    private func write(_ records: [SwappedRecord], to url: URL) {
        let encoder = JSONEncoder()
        let data = try? encoder.encode(records)
        try? data?.write(to: url.appendingPathComponent(HybridStorage.metadataFilename))
    }

    private func readRecords(from url: URL) -> [SwappedRecord] {
        let decoder = JSONDecoder()
        guard let data = try? Data(contentsOf: url.appendingPathComponent(HybridStorage.metadataFilename)),
            let records = try? decoder.decode([SwappedRecord].self, from: data) else {
            return []
        }
        return records
    }

}
