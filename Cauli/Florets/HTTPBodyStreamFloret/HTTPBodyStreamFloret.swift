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

/// The `HTTPBodyStreamFloret` can modify a `Record` where the request uses a `httpBodyStream`
/// instead of setting the data on the request itself.
/// It will read all data from the stream and set it as data on the request. This is helpful
/// if you want to inspect `Record`s in the storage or want to modify the requests body
/// before it is sent to the server.
public class HTTPBodyStreamFloret: InterceptingFloret {
    private static let bufferByteSize = 1024

    private let maximumConvertedByteSize: Int64
    public var enabled: Bool = true

    /// Will create a new `HTTPBodyStreamFloret` instance.
    ///
    /// - Parameter maximumConvertedByteSize: The maximum size until which the data should be
    ///     converted. Once more data is read from the `httpBodyStream`, the record will not be
    ///     changed and the `httpBodyStream` is kept. Default is 50 * 1024.
    public init(maximumConvertedByteSize: Int64 = 50 * 1024 ) {
        self.maximumConvertedByteSize = maximumConvertedByteSize
    }

    public func willRequest(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        guard let httpBodyStream = record.designatedRequest.httpBodyStream,
            let data = data(reading: httpBodyStream) else {
            return completionHandler(record)
        }
        var record = record
        record.designatedRequest.httpBodyStream = nil
        record.designatedRequest.httpBody = data
        completionHandler(record)
    }

    public func didRespond(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        completionHandler(record)
    }

    private func data(reading input: InputStream) -> Data? {
        var data = Data()
        input.open()
        defer {
            input.close()
        }

        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: HTTPBodyStreamFloret.bufferByteSize)
        defer {
            buffer.deallocate()
        }

        while input.hasBytesAvailable {
            if data.count > maximumConvertedByteSize { return nil }
            let read = input.read(buffer, maxLength: HTTPBodyStreamFloret.bufferByteSize)
            data.append(buffer, count: read)
        }

        return data
    }

}
