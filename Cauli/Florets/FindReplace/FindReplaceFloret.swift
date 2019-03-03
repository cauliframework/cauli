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

/// A `FindReplaceFloret` uses `RecordModifier`s to modify a `Record`
/// before sending a request and after receiving a response. Use multiple
/// instances of the `FindReplaceFloret`s to group certain RecordModifiers
/// under a given name.
public class FindReplaceFloret: InterceptingFloret {

    public var enabled: Bool = true
    public let name: String

    private let willRequestModifiers: [RecordModifier]
    private let didRespondModifiers: [RecordModifier]

    /// This init will create a FindReplaceFloret with RecordModifiers to modify Records.
    ///
    /// - Parameters:
    ///   - willRequestModifiers: The RecordModifiers used to modify a Record before sending a request.
    ///   - didRespondModifiers: The RecordModifiers used to modify a Record after receiving a response.
    ///   - name: Can be used to describe the set of choosen RecordModifiers. The default name is `FindReplaceFloret`.
    public init(willRequestModifiers: [RecordModifier] = [], didRespondModifiers: [RecordModifier] = [], name: String = "FindReplaceFloret") {
        self.willRequestModifiers = willRequestModifiers
        self.didRespondModifiers = didRespondModifiers
        self.name = name
    }

    public func willRequest(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        let record = willRequestModifiers.reduce(record) { record, recordModifier in
            recordModifier.modify(record)
        }

        completionHandler(record)
    }

    public func didRespond(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        let record = didRespondModifiers.reduce(record) { record, recordModifier in
            recordModifier.modify(record)
        }

        completionHandler(record)
    }
}
