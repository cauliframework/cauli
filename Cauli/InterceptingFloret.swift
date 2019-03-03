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

/// An InterceptingFloret can process requests and responses.
public protocol InterceptingFloret: Floret {

    /// If an InterceptingFloret is disabled both functions `willRequest` and `didRespond` will
    /// not be called anymore. A InterceptingFloret doesn't need to perform any specific action.
    var enabled: Bool { get set }

    /// This function will be called before a request is performed. The InterceptingFlorets will be
    /// called in the order the Cauli instance got initialized with.
    ///
    /// Using this function you can:
    /// - inspect the request
    /// - modify the request (update the `designatedRequest`)
    /// - fail the request (set the `result` to `.error()`)
    /// - return a cached or pre-calculated response (set the `result` to `.result()`)
    ///
    /// - Parameters:
    ///   - record: The `Record` that represents the request before it was performed.
    ///   - completionHandler: Call this completion handler exactly once with the
    ///     original or modified `Record`.
    func willRequest(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void)

    /// This function will be called after a request is performed and the response arrived.
    /// The InterceptingFlorets will be called in the order the Cauli instance got initialized with.
    ///
    /// Using this function you can:
    /// - modify the request
    ///
    /// - Parameters:
    ///   - record: The `Record` that represents the request after it was performed.
    ///   - completionHandler: Call this completion handler exactly once with the
    ///     original or modified `Record`.
    func didRespond(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void)
}
