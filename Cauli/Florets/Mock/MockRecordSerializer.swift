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

internal class MockRecordSerializer {

    /// Returns a path to a temporary folder where a record is written to.
    ///
    /// - Parameter record: The record to write on disk.
    /// - Returns: The path to the temporary folder.
    static func write(record: Record) -> URL? {
        let tempPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString, isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: tempPath, withIntermediateDirectories: true, attributes: nil)
            let swappedRecord = record.swapped(to: tempPath)
            guard let data = self.data(for: swappedRecord) else { return nil }
            let filepath = tempPath.appendingPathComponent("record.json")
            try data.write(to: filepath)
        } catch {
            try? FileManager.default.removeItem(at: tempPath)
            return nil
        }

        return tempPath
    }

    static func record(from folder: URL) -> Record? {
        let filepath = folder.appendingPathComponent("record.json")
        if let data = try? Data(contentsOf: filepath),
            let swappedRecord = MockRecordSerializer.record(with: data) {
            return swappedRecord.record(in: folder)
        } else {
            return nil
        }
    }

    private static func data(for record: SwappedRecord) -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(record) else { return nil }
        return data
    }

    private static func record(with data: Data) -> SwappedRecord? {
        let decoder = JSONDecoder()
        guard let record = try? decoder.decode(SwappedRecord.self, from: data) else { return nil }
        return record
    }

}
