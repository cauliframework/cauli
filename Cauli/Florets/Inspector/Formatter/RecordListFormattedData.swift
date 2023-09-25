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

import UIKit

extension InspectorFloret {
    /// The RecordListFormattedData defines the data shown
    /// in the Record list in the InspectorFloret.
    public struct RecordListFormattedData {
        /// The string shown in the method label
        public let method: String
        /// The string shown in the path label
        public let path: String
        /// The string shown in the time label
        public let time: String
        /// The string shown in the status label
        public let status: String
        /// The background color of the status label.
        /// The text color of the status label will be white.
        public let statusColor: UIColor

        public init(method: String, path: String, time: String, status: String, statusColor: UIColor) {
            self.method = method
            self.path = path
            self.time = time
            self.status = status
            self.statusColor = statusColor
        }
    }
}
