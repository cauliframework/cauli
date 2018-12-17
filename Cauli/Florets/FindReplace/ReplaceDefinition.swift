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

extension FindReplaceFloret {
    /// A ReplaceDefinition defines the replacement of a Record
    public struct ReplaceDefinition {
        /// This closures is called when a Record can be modified.
        /// It can return a modified Record or the original Record.
        let modifier: (Record) -> (Record)
    }
}

extension FindReplaceFloret.ReplaceDefinition {
    /// This init is based on a Records keyPath and allows just to modify
    /// a specific property of a Record.
    ///
    /// - Parameters:
    ///   - keyPath: The keyPath describing which property of a Record should be modified.
    ///   - modifier: A closure used to modify the property defined by the keyPath.
    /// - Returns: A ReplaceDefinition modifying a specific property of a Record.
    ///            Use this to initalize a FindReplaceFloret.
    public init<Type>(keyPath: WritableKeyPath<Record, Type>, modifier: @escaping (Type) -> (Type)) {
        self.init { record in
            var newRecord = record
            let oldValue = record[keyPath: keyPath]
            let modifiedValue = modifier(oldValue)
            newRecord[keyPath: keyPath] = modifiedValue
            return newRecord
        }
    }
}

extension FindReplaceFloret.ReplaceDefinition {
    /// This init will modify the Requests URL.
    ///
    /// - Parameters:
    ///   - expression: A RegularExpression describing the part of the Requets URL to modify.
    ///   - replacement: The replacement string used to replace matches of the RegularExpression.
    /// - Returns: A ReplaceDefinition modifying the RequestURL. Use this to initalize a FindReplaceFloret.
    public static func modifyUrl(expression: NSRegularExpression, replacement: String) -> FindReplaceFloret.ReplaceDefinition {
        let keyPath = \Record.designatedRequest.url
        let modifier: (URL?) -> (URL?) = { url in
            guard let oldURL = url else { return url }
            let urlWithReplacements = replacingOcurrences(of: expression, in: oldURL.absoluteString, with: replacement)
            return URL(string: urlWithReplacements)
        }
        return FindReplaceFloret.ReplaceDefinition(keyPath: keyPath, modifier: modifier)
    }

    static func replacingOcurrences(of expression: NSRegularExpression, in string: String, with template: String) -> String {
        let range = NSRange(string.startIndex..., in: string)
        return expression.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: template)
    }
}
