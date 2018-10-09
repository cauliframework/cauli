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

    // We could use such a blacklist to remove HTTP Headers before serializing the data
    // I guess these fields should only affect the path, not the actual serialized data, right?
    // Maybe we should only hash the actual content of a request?
    // static let headersBlacklist: [AnyHashable] = ["Date"]

    static func data(for record: Record) -> Data? {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(record) else { return nil }
        return data
    }

    static func record(with data: Data) -> Record? {
        let decoder = JSONDecoder()
        guard let record = try? decoder.decode(Record.self, from: data) else { return nil }
        return record
    }

}
