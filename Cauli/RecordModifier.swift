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

/// A RecordModifier defines the modification of a Record
public struct RecordModifier {
        /// modify closure defines a Record modification. It can return the original record or a modified record.
        /// It should not return a new record/a record with a new UUID.
        let modify: (Record) -> (Record)
}

extension RecordModifier {
    /// This init is based on a Records keyPath and allows just to modify
    /// a specific property of a Record.
    ///
    /// - Parameters:
    ///   - keyPath: The keyPath describing which property of a Record should be modified.
    ///   - modifier: A closure used to modify the property defined by the keyPath.
    /// - Returns: A RecordModifier is modifying a specific property of a Record.
    ///            Used for example to initalize a FindReplaceFloret.
    public init<Type>(keyPath: WritableKeyPath<Record, Type>, modifier: @escaping (Type) -> (Type)) {
        self.init { record in
            var newRecord = record
            let oldValue = record[keyPath: keyPath]
            let modifiedValue = modifier(oldValue)
            newRecord[keyPath: keyPath] = modifiedValue
            return newRecord
        }
    }

    /// This init will modify the Requests URL.
    ///
    /// - Parameters:
    ///   - expression: A RegularExpression describing the part of the Requets URL to modify.
    ///   - template: The substitution template used when replacing matching instances of the expression.
    /// - Returns: A RecordModifier is modifying the RequestURL. Used to initalize a FindReplaceFloret.
    public static func modifyUrl(expression: NSRegularExpression, template: String) -> RecordModifier {
        let keyPath = \Record.designatedRequest.url
        let modifier: (URL?) -> (URL?) = { url in
            guard let oldURL = url else { return url }
            let urlWithReplacements = replacingOcurrences(of: expression, in: oldURL.absoluteString, with: template)
            return URL(string: urlWithReplacements)
        }
        return RecordModifier(keyPath: keyPath, modifier: modifier)
    }

    static func replacingOcurrences(of expression: NSRegularExpression, in string: String, with template: String) -> String {
        let range = NSRange(string.startIndex..., in: string)
        return expression.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: template)
    }
}
