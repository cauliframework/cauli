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
import Quick
import Nimble

class FilecachedInputOutputStreamSpec: QuickSpec {
    override func spec() {
        describe("hasBytesAvailable") {
            it("should be true if the outputstream isn't closed even if no data was written before") {
                let stream = FilecachedInputOutputStream()
                expect(stream.hasBytesAvailable) == true
            }
            it("should be false if the outputstream is closed") {
                let stream = FilecachedInputOutputStream()
                stream.writableOutputStream?.close()
                expect(stream.hasBytesAvailable) == false
            }
            it("should be false if the outputstream is closed, even if unread data was written to") {
                let stream = FilecachedInputOutputStream()
                let data = "spec_data".data(using: .utf8)!
                _ = data.withUnsafeBytes { stream.writableOutputStream?.write($0, maxLength: data.count) }
                stream.writableOutputStream?.close()
                expect(stream.hasBytesAvailable) == false
            }
        }
        describe("read") {
            it("shouldn't read any data if nothing was written to it") {
                let stream = FilecachedInputOutputStream()
                stream.open()
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1024)
                let readBytes = stream.read(buffer, maxLength: 1024)
                expect(readBytes) == 0
            }
            it("shouldn't read the same data that was written to the output stream") {
                let stream = FilecachedInputOutputStream()
                let writtenData = "spec_data".data(using: .utf8)!
                _ = writtenData.withUnsafeBytes { stream.writableOutputStream?.write($0, maxLength: writtenData.count) }
                stream.open()
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1024)
                let readBytes = stream.read(buffer, maxLength: 1024)
                let readData = Data(bytes: buffer, count: readBytes)
                expect(readBytes) == writtenData.count
                expect(readData) == writtenData
            }
        }
    }
    
    private func tempfile() -> URL {
        let tempfolder = URL(fileURLWithPath: NSTemporaryDirectory())
        return tempfolder.appendingPathComponent(UUID().uuidString)
    }
}
