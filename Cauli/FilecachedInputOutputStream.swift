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

internal class FilecachedInputOutputStream: InputStream {

    let readableInputStream: InputStream
    let writableOutputStream: OutputStream?

    init() {
        let tempfolder = URL(fileURLWithPath: NSTemporaryDirectory())
        let tempfile = tempfolder.appendingPathComponent(UUID().uuidString)
        writableOutputStream = OutputStream(url: tempfile, append: true)
        writableOutputStream?.open()
        readableInputStream = InputStream(url: tempfile)!
        super.init(url: tempfile)!
    }

    override var hasBytesAvailable: Bool {
        return writableOutputStream?.streamStatus != .closed || readableInputStream.hasBytesAvailable
    }

    override func open() {
        readableInputStream.open()
    }

    override func close() {
        readableInputStream.close()
    }

    override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        return readableInputStream.read(buffer, maxLength: len)
    }

    override func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool {
        return readableInputStream.getBuffer(buffer, length: len)
    }

}

extension OutputStream {
    @discardableResult internal func cauli_write(_ data: Data) -> Int {
        return data.withUnsafeBytes { write($0, maxLength: data.count) }
    }

    internal func cauli_write(_ input: InputStream) {
        input.cauli_readData(iteration: { [weak self] data in
            self?.cauli_write(data)
        })
    }
}

extension InputStream {

    // swiftlint:disable identifier_name
    private static let cauli_bufferByteSize = 1024
    // swiftlint:enable identifier_name

    internal func cauli_data() -> Data? {
        var data = Data()
        open()
        defer {
            close()
        }

        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: InputStream.cauli_bufferByteSize)
        defer {
            buffer.deallocate()
        }

        while hasBytesAvailable {
            let readBytes = read(buffer, maxLength: InputStream.cauli_bufferByteSize)
            data.append(buffer, count: readBytes)
        }

        return data
    }

    internal func cauli_readData(iteration: (Data) -> Void, completion: (() -> Void)? = nil) {
        let bufferByteSize = 1024
        open()
        defer {
            close()
        }

        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: InputStream.cauli_bufferByteSize)
        defer {
            buffer.deallocate()
        }

        while hasBytesAvailable {
            var data = Data()
            let readBytes = read(buffer, maxLength: InputStream.cauli_bufferByteSize)
            data.append(buffer, count: readBytes)
            if readBytes > 0 {
                iteration(data)
            }
        }
        completion?()
    }

    internal func cauli_write(to fileUrl: URL) throws {
        FileManager.default.createFile(atPath: fileUrl.path, contents: nil, attributes: nil)
        schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)
        open()
        let fileHandle = try FileHandle(forWritingTo: fileUrl)
        cauli_readData(iteration: { data in
            fileHandle.write(data)
        }, completion: {
            fileHandle.closeFile()
        })
    }
}
