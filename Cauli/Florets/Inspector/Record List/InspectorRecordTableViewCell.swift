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

    static let timeFormatter: DateFormatter = {
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        return timeFormatter
    }()

    static let reuseIdentifier = "InspectorRecordTableViewCell"
    static let nibName = "InspectorRecordTableViewCell"

    @IBOutlet private weak var methodLabel: TagLabel!
    @IBOutlet private weak var pathLabel: UILabel!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var contentTypeLabel: UILabel!
    @IBOutlet private weak var statusCodeLabel: TagLabel!

    internal func configure(with record: Record, stringToHighlight: String?) {
        if let requestStarted = record.requestStarted {
            timeLabel.text = InspectorRecordTableViewCell.timeFormatter.string(from: requestStarted)
        } else {
            timeLabel.text = ""
        }
        methodLabel.text = record.designatedRequest.httpMethod
        let pathString = record.designatedRequest.url?.absoluteString ?? ""
        let pathAttributedString = NSMutableAttributedString(string: pathString)
        if let stringToHighlight = stringToHighlight {
            var rangeToSearch = pathString.startIndex..<pathString.endIndex
            while let matchingRange = pathString.range(of: stringToHighlight, options: String.CompareOptions.caseInsensitive, range: rangeToSearch) {
                pathAttributedString.addAttributes([.font: UIFont.boldSystemFont(ofSize: pathLabel.font.pointSize), .foregroundColor: tintColor], range: NSRange(matchingRange, in: pathString))
                rangeToSearch = matchingRange.upperBound..<pathString.endIndex
            }
        }
        pathLabel.attributedText = pathAttributedString
        switch record.result {
        case nil:
            contentTypeLabel.text = ""
            statusCodeLabel.text = "no Response"
            statusCodeLabel.borderColor = .black
        case .error(let error)?:
            contentTypeLabel.text = error.localizedDescription
            statusCodeLabel.text = "Error"
            statusCodeLabel.borderColor = InspectorRecordTableViewCell.redColor
        case .result(let response)?:
            if let httpUrlResponse = response.urlResponse as? HTTPURLResponse {
                contentTypeLabel.text = httpUrlResponse.allHeaderFields["Content-Type"] as? String
                statusCodeLabel.text = "\(httpUrlResponse.statusCode)"
                statusCodeLabel.borderColor = colorForHTTPStatusCode(httpUrlResponse.statusCode)
            }
        }
    }

    static let greenColor = UIColor(displayP3Red: 126 / 255.0, green: 211 / 255.0, blue: 33 / 255.0, alpha: 1)
    static let blueColor = UIColor(displayP3Red: 74 / 255.0, green: 144 / 255.0, blue: 226 / 255.0, alpha: 1)
    static let redColor = UIColor(displayP3Red: 208 / 255.0, green: 2 / 255.0, blue: 27 / 255.0, alpha: 1)
    private func colorForHTTPStatusCode(_ statusCode: Int) -> UIColor {
        switch statusCode {
        case 0..<300: return InspectorRecordTableViewCell.greenColor
        case 300..<400: return InspectorRecordTableViewCell.blueColor
        case 400..<600: return InspectorRecordTableViewCell.redColor
        default: return UIColor.black
        }
    }
}
