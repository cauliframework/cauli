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

public struct ReplaceDefinition {
    let modifier: (Record) -> (Record)
}

extension ReplaceDefinition {
    public init<Type>(keyPath: WritableKeyPath<Record, Type>, replacer: @escaping (Type) -> (Type)) {
        self.init { record in
            var newRecord = record
            let oldValue = record[keyPath: keyPath]
            let modifiedValue = replacer(oldValue)
            newRecord[keyPath: keyPath] = modifiedValue
            return newRecord
        }
    }
}

extension ReplaceDefinition {
    public static func modifyUrl(expression: NSRegularExpression, replacement: String) -> ReplaceDefinition {
        let keyPath = \Record.designatedRequest.url
        let replacer: (URL?) -> (URL?) = { url in
            guard let oldURL = url else { return url }
            return URL(string: oldURL.absoluteString.replacingOcurrences(of: expression, with: replacement))
        }
        return ReplaceDefinition(keyPath: keyPath, replacer: replacer)
    }
}
