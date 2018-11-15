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

/// A RecordSelector defines a selection of a Record object. It is used in the `Configuration.recordSelector` to
/// define a subset of Records that should be handled by a Cauli instance.
public struct RecordSelector {
    internal let selects: (Record) -> (Bool)

    public init(selects: @escaping (Record) -> (Bool)) {
        self.selects = selects
    }
}

extension RecordSelector {
    /// Selects every Record.
    ///
    /// - Returns: Returns a RecordSelector where every Record is selected.
    static func all() -> RecordSelector {
        return RecordSelector { _ in true }
    }

    /// Selects Records by a maximum filesize
    ///
    /// - Parameter bytesize: The maximum size in bytes of the Response body.
    /// - Returns: Returns a RecordSelector that selects only the Records where the body is smaller or
    ///     equal than the required size.
    static func max(bytesize: Int) -> RecordSelector {
        return RecordSelector { record in
            switch record.result {
            case .none: return true
            case .error: return true
            case .result(let response):
                if let data = response.data {
                    return data.count <= bytesize
                } else if let urlResponse = response.urlResponse as? HTTPURLResponse,
                    let contentLength = urlResponse.allHeaderFields["Content-Length"] as? Int {
                    return contentLength <= bytesize
                }
                return false
            }
        }
    }
}
