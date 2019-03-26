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

    private let folder: URL
    private var recordsFolder: URL {
        return folder.appendingPathComponent("records")
    }
    private var records: [Record] = []
    var capacity: StorageCapacity = .unlimited {
        didSet {
            ensureCapacity()
        }
    }
    var preStorageRecordModifier: RecordModifier?

    convenience init() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let documentsUrl = URL(fileURLWithPath: documentsPath)
        self.init(folder: documentsUrl.appendingPathComponent("cauli"))
    }

    init(folder: URL) {
        self.folder = folder
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("failed to create storage folder: \(error)")
        }
        self.records = readRecords()
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
        write(records)
    }

    func records<T: Comparable>(with predicate: NSPredicate?, sortedBy keyPath: KeyPath<Record, T?>, ascending: Bool, limit: Int, after record: Record?) -> [Record] {
        assert(Thread.isMainThread, "\(#file):\(#line) must run on the main thread!")
        let records = self.records.filtered(using: predicate).sorted(by: keyPath, ascending: ascending)
        let index: Int
        if let record = record,
            let recordIndex = records.index(where: { $0.identifier == record.identifier }) {
            index = recordIndex + 1
        } else {
            index = 0
        }
        let maxCount = min(limit, records.count - index)
        return Array(records[index..<(index + maxCount)])
    }

    func storeRequestBody(_ stream: InputStream, for record: Record) {
        let filepath = requestBodyFileUrl(for: record)
        do {
            try stream.cauli_write(to: filepath)
        } catch {
            print("failed to write data to disk: \(error)")
        }
    }

    func requestBody(for record: Record) -> InputStream? {
        let filepath = requestBodyFileUrl(for: record)
        guard FileManager.default.fileExists(atPath: filepath.path) else { return nil }
        return InputStream(url: filepath)
    }

    func storeResponseBody(_ stream: InputStream, for record: Record) {
        let filepath = responseBodyFileUrl(for: record)
        do {
            try stream.cauli_write(to: filepath)
        } catch {
            print("failed to write data to disk: \(error)")
        }
    }

    func responseBody(for record: Record) -> InputStream? {
        let filepath = responseBodyFileUrl(for: record)
        guard FileManager.default.fileExists(atPath: filepath.path) else { return nil }
        return InputStream(url: filepath)
    }

    private func ensureCapacity() {
        // TODO: delete the folders for the records that got deleted
        switch capacity {
        case .unlimited: return
        case .records(let maximumRecordCount):
            records = Array(records.prefix(maximumRecordCount))
        }
        write(records)
    }

    private func requestBodyFileUrl(for record: Record) -> URL {
        let recordFolder = recordsFolder.appendingPathComponent(record.identifier.uuidString)
        do {
            try FileManager.default.createDirectory(at: recordFolder, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("failed to create storage folder: \(error)")
        }
        return recordFolder.appendingPathComponent("request")
    }

    private func responseBodyFileUrl(for record: Record) -> URL {
        let recordFolder = recordsFolder.appendingPathComponent(record.identifier.uuidString)
        do {
            try FileManager.default.createDirectory(at: recordFolder, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("failed to create storage folder: \(error)")
        }
        return recordFolder.appendingPathComponent("response")
    }
}

extension MemoryStorage {

    static let metadataFilename = "MemoryStorage.records.json"

    private func write(_ records: [Record]) {
        let encoder = JSONEncoder()
        let data = try? encoder.encode(records)
        try? data?.write(to: folder.appendingPathComponent(MemoryStorage.metadataFilename))
    }

    private func readRecords() -> [Record] {
        let decoder = JSONDecoder()
        guard let data = try? Data(contentsOf: folder.appendingPathComponent(MemoryStorage.metadataFilename)),
            let records = try? decoder.decode([Record].self, from: data) else {
                return []
        }
        return records
    }

}

extension Array {
    func filtered(using predicate: NSPredicate?) -> [Element] {
        guard let predicate = predicate else { return self }
        return filter { predicate.evaluate(with: $0) }
    }

    func sorted<T: Comparable>(by keyPath: KeyPath<Element, T?>, ascending: Bool) -> [Element] {
        return sorted { lhs, rhs in
            guard let lhsValue = lhs[keyPath: keyPath] else {
                return !ascending
            }
            guard let rhsValue = rhs[keyPath: keyPath] else {
                return ascending
            }
            if ascending {
                return lhsValue < rhsValue
            } else {
                return lhsValue > rhsValue
            }
        }
    }
}
