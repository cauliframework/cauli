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

// swiftlint:disable nesting
extension NSError {

    /// All Cauli related Errors.
    public struct Cauli {

        /// The Cauli NSErrorDomain.
        public let domain = "works.cauli.framework"

        /// All Cauli Error Codes.
        public enum Code {}

        /// All keys used in Cauli Errors.
        public enum UserInfoKey {}
    }

    internal struct CauliInternal {
        internal static let domain = "works.cauli.framework.internal"
        internal enum Code: Int {
            case failedToAppendData
            case appendingDataWithoutResponse
        }

        internal enum UserInfoKey: String {
            case data
            case record
        }

        internal static func failedToAppendData(_ data: Data, record: Record) -> NSError {
            return NSError(domain: domain,
                           code: Code.failedToAppendData.rawValue,
                           userInfo: [UserInfoKey.data.rawValue: data, UserInfoKey.record.rawValue: record])
        }

        internal static func appendingDataWithoutResponse(_ data: Data, record: Record) -> NSError {
            return NSError(domain: domain,
                           code: Code.appendingDataWithoutResponse.rawValue,
                           userInfo: [UserInfoKey.data.rawValue: data, UserInfoKey.record.rawValue: record])
        }
    }
}
