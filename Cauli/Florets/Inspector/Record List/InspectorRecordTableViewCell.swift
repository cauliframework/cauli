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

internal class InspectorRecordTableViewCell: UITableViewCell {

    static let reuseIdentifier = "InspectorRecordTableViewCell"
    static let nibName = "InspectorRecordTableViewCell"

    @IBOutlet private weak var methodLabel: UILabel!
    @IBOutlet private weak var pathLabel: UILabel!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var statusCodeLabel: TagLabel!

    internal func configure(with data: InspectorFloret.RecordListFormattedData, stringToHighlight: String?) {
        timeLabel.text = data.time
        methodLabel.text = data.method
        let pathString = data.path
        let pathAttributedString = NSMutableAttributedString(string: pathString)
        if let stringToHighlight = stringToHighlight {
            var rangeToSearch = pathString.startIndex..<pathString.endIndex
            while let matchingRange = pathString.range(of: stringToHighlight, options: String.CompareOptions.caseInsensitive, range: rangeToSearch) {
                pathAttributedString.addAttributes([.font: UIFont.boldSystemFont(ofSize: pathLabel.font.pointSize), .foregroundColor: tintColor], range: NSRange(matchingRange, in: pathString))
                rangeToSearch = matchingRange.upperBound..<pathString.endIndex
            }
        }
        pathLabel.attributedText = pathAttributedString
        statusCodeLabel.text = data.status
        statusCodeLabel.backgroundColor = data.statusColor
    }
}
