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
    public var enabled = true

    /// Temporary files holding the bodies that exceeded `maximumConvertedByteSize`, by record.
    private var temporaryFiles: [UUID: URL] = [:]
    private let temporaryFilesLock = NSLock()

    /// Will create a new `HTTPBodyStreamFloret` instance.
    ///
    /// - Parameter maximumConvertedByteSize: The maximum size until which the data should be
    ///     converted. Once more data is read from the `httpBodyStream`, the body is kept as a
    ///     `httpBodyStream`, backed by a temporary file, so the request is still sent with its
    ///     complete body. Default is 50 * 1024.
    public init(maximumConvertedByteSize: Int64 = 50 * 1024 ) {
        self.maximumConvertedByteSize = maximumConvertedByteSize
    }

    public func willRequest(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        guard let httpBodyStream = record.designatedRequest.httpBodyStream else {
            return completionHandler(record)
        }
        var record = record
        switch body(reading: httpBodyStream) {
        case .data(let data):
            record.designatedRequest.httpBodyStream = nil
            record.designatedRequest.httpBody = data
        case let .stream(stream, temporaryFile):
            record.designatedRequest.httpBodyStream = stream
            if let temporaryFile = temporaryFile {
                setTemporaryFile(temporaryFile, for: record)
            }
        case .unreadable:
            // The stream failed, so there is no body to send. The request is left as it is.
            break
        }
        completionHandler(record)
    }

    public func didRespond(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        if let temporaryFile = removeTemporaryFile(for: record) {
            try? FileManager.default.removeItem(at: temporaryFile)
        }
        completionHandler(record)
    }
}

private extension HTTPBodyStreamFloret {
    enum Body {
        /// The complete body, within the `maximumConvertedByteSize`.
        case data(Data)
        /// A new stream with the complete body, since it exceeded the `maximumConvertedByteSize`.
        /// It reads from `temporaryFile`, or from memory if no temporary file could be written.
        case stream(InputStream, temporaryFile: URL?)
        /// The stream failed while reading.
        case unreadable
    }

    /// A temporary file the body is written to, once it exceeds the `maximumConvertedByteSize`.
    struct Spillover {
        let url: URL
        let stream: OutputStream

        func discard() {
            stream.close()
            try? FileManager.default.removeItem(at: url)
        }
    }

    /// Reads the complete stream. The original stream can't be read again afterwards,
    /// so every byte read has to end up in the returned `Body`.
    func body(reading input: InputStream) -> Body {
        input.open()
        defer {
            input.close()
        }

        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: HTTPBodyStreamFloret.bufferByteSize)
        defer {
            buffer.deallocate()
        }

        var data = Data()
        var spillover: Spillover?
        var canSpill = true

        while input.hasBytesAvailable {
            let read = input.read(buffer, maxLength: HTTPBodyStreamFloret.bufferByteSize)
            if read < 0 {
                spillover?.discard()
                return .unreadable
            }
            if read == 0 {
                break
            }

            if let currentSpillover = spillover {
                let written = write(buffer, count: read, to: currentSpillover.stream)
                if written == read {
                    continue
                }
                // Writing the temporary file failed. Continue in memory with everything read so far.
                currentSpillover.stream.close()
                let restored = try? Data(contentsOf: currentSpillover.url)
                currentSpillover.discard()
                guard var restoredData = restored else { return .unreadable }
                restoredData.append(buffer + written, count: read - written)
                data = restoredData
                spillover = nil
                canSpill = false
                continue
            }

            data.append(buffer, count: read)
            if canSpill && Int64(data.count) > maximumConvertedByteSize {
                if let newSpillover = makeSpillover(startingWith: data) {
                    spillover = newSpillover
                    data = Data()
                } else {
                    canSpill = false
                }
            }
        }

        if let spillover = spillover {
            return body(from: spillover)
        }
        if Int64(data.count) > maximumConvertedByteSize {
            return .stream(InputStream(data: data), temporaryFile: nil)
        }
        return .data(data)
    }

    /// Finishes writing the temporary file and returns a stream reading the body from it.
    func body(from spillover: Spillover) -> Body {
        spillover.stream.close()
        if let stream = InputStream(url: spillover.url) {
            return .stream(stream, temporaryFile: spillover.url)
        }
        let restored = try? Data(contentsOf: spillover.url)
        spillover.discard()
        guard let restoredData = restored else { return .unreadable }
        return .stream(InputStream(data: restoredData), temporaryFile: nil)
    }

    /// Creates a temporary file containing `data`, to which the rest of the body is written.
    func makeSpillover(startingWith data: Data) -> Spillover? {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("cauli-httpbody-\(UUID().uuidString)")
        guard let stream = OutputStream(url: url, append: false) else { return nil }
        stream.open()
        let spillover = Spillover(url: url, stream: stream)
        let written = data.withUnsafeBytes { rawBuffer -> Int in
            guard let bytes = rawBuffer.bindMemory(to: UInt8.self).baseAddress else { return 0 }
            return write(bytes, count: data.count, to: stream)
        }
        guard written == data.count else {
            spillover.discard()
            return nil
        }
        return spillover
    }

    /// Writes up to `count` bytes and returns how many were written before an error occurred.
    func write(_ bytes: UnsafePointer<UInt8>, count: Int, to stream: OutputStream) -> Int {
        var offset = 0
        while offset < count {
            let written = stream.write(bytes + offset, maxLength: count - offset)
            guard written > 0 else { break }
            offset += written
        }
        return offset
    }

    func setTemporaryFile(_ url: URL, for record: Record) {
        temporaryFilesLock.lock()
        temporaryFiles[record.identifier] = url
        temporaryFilesLock.unlock()
    }

    func removeTemporaryFile(for record: Record) -> URL? {
        temporaryFilesLock.lock()
        defer { temporaryFilesLock.unlock() }
        return temporaryFiles.removeValue(forKey: record.identifier)
    }
}
