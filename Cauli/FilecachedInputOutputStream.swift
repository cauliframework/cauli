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

/// The FilecachedInputOutputStream is an InputStream that can be written to.
/// Every byte written to the stream is first written to a temp file before
/// it can be read from.
internal class FilecachedInputOutputStream: InputStream {

    let writableOutputStream: OutputStream?

    private let cacheFile: URL
    private let readableInputStream: InputStream

    deinit {
        DispatchQueue.global(qos: .background).async { [cacheFile] in
            do {
                try FileManager.default.removeItem(at: cacheFile)
            } catch (let error as NSError)
                where error.domain == NSCocoaErrorDomain && error.code == NSFileNoSuchFileError {
                    // All good. File doesn't exist.
            } catch {
                print("Failed to delete temporary file with path: \(cacheFile)")
            }
        }
    }

    init(fileCache: URL) {
        writableOutputStream = OutputStream(url: fileCache, append: true)
        writableOutputStream?.open()
        readableInputStream = InputStream(url: fileCache)!
        cacheFile = fileCache
        super.init(url: fileCache)!
    }

    convenience init() {
        let tempfolder = URL(fileURLWithPath: NSTemporaryDirectory())
        let tempfile = tempfolder.appendingPathComponent(UUID().uuidString)
        self.init(fileCache: tempfile)
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
