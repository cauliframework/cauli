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
        timeFormatter.timeStyle = .medium
        return timeFormatter
    }()

    static let reuseIdentifier = "InspectorRecordTableViewCell"
    static let nibName = "InspectorRecordTableViewCell"

    @IBOutlet private weak var methodLabel: UILabel!
    @IBOutlet private weak var pathLabel: UILabel!
    @IBOutlet private weak var timeLabel: UILabel!
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
            statusCodeLabel.text = "-"
            statusCodeLabel.backgroundColor = UIColor(red: 1080 / 255.0, green: 117 / 255.0, blue: 125 / 255.0, alpha: 1)
        case .error(let error)?:
            statusCodeLabel.text = errorString(for: error.code)
            statusCodeLabel.backgroundColor = InspectorRecordTableViewCell.redColor
        case .result(let response)?:
            if let httpUrlResponse = response.urlResponse as? HTTPURLResponse {
                statusCodeLabel.text = "\(httpUrlResponse.statusCode)"
                statusCodeLabel.backgroundColor = colorForHTTPStatusCode(httpUrlResponse.statusCode)
            }
        }
    }

    static let greenColor = UIColor(red: 11 / 255.0, green: 176 / 255.0, blue: 61 / 255.0, alpha: 1)
    static let blueColor = UIColor(red: 74 / 255.0, green: 144 / 255.0, blue: 226 / 255.0, alpha: 1)
    static let redColor = UIColor(red: 210 / 255.0, green: 46 / 255.0, blue: 14 / 255.0, alpha: 1)
    static let grayColor = UIColor(red: 155 / 255.0, green: 155 / 255.0, blue: 155 / 255.0, alpha: 1)
    private func colorForHTTPStatusCode(_ statusCode: Int) -> UIColor {
        switch statusCode {
        case 0..<300: return InspectorRecordTableViewCell.greenColor
        case 300..<400: return InspectorRecordTableViewCell.blueColor
        case 400..<600: return InspectorRecordTableViewCell.redColor
        default: return InspectorRecordTableViewCell.grayColor
        }
    }
    
    private func errorString(for code: Int) -> String {
        guard let error = CFNetworkErrors(rawValue: Int32(code)) else {
            return "Error"
        }
        switch error {
        case .cfHostErrorHostNotFound, .cfurlErrorCannotFindHost:
            return "Host not found"
        case .cfHostErrorUnknown:
            return "Unknown error"
        case .cfftpErrorUnexpectedStatusCode:
            return "Unexpected status code"
        case .cfErrorHTTPAuthenticationTypeUnsupported:
            return "Unsupported auth type"
        case .cfErrorHTTPBadCredentials:
            return "Bad credentials"
        case .cfErrorHTTPConnectionLost, .cfurlErrorNetworkConnectionLost:
            return "Connection lost"
        case .cfErrorHTTPParseFailure:
            return "Parse failure"
        case .cfErrorHTTPRedirectionLoopDetected:
            return "Redirect loop"
        case .cfurlErrorBadURL, .cfErrorHTTPBadURL:
            return "Bad URL"
        case .cfErrorHTTPProxyConnectionFailure, .cfErrorHTTPSProxyConnectionFailure:
            return "Proxy connection failure"
        case .cfErrorHTTPBadProxyCredentials:
            return "Bad proxy credentials"
        case .cfErrorPACFileError:
            return "Proxy config error"
        case .cfErrorPACFileAuth:
            return "Proxy auth failure"
        case .cfurlErrorUnsupportedURL:
            return "Unsupported URL"
        case .cfurlErrorCannotConnectToHost:
            return "Cannot connect to host"
        case .cfurlErrorDNSLookupFailed:
            return "DNS lookup failed"
        case .cfurlErrorHTTPTooManyRedirects:
            return "Too many redirects"
        case .cfurlErrorResourceUnavailable:
            return "Resource unavailable"
        case .cfurlErrorNotConnectedToInternet:
            return "Offline"
        case .cfurlErrorRedirectToNonExistentLocation:
            return "Failed redirect"
        case .cfurlErrorBadServerResponse:
            return "Bad server response"
        case .cfurlErrorUserCancelledAuthentication:
            return "Auth cancelled"
        case .cfurlErrorUserAuthenticationRequired:
            return "Auth required"
        case .cfurlErrorTimedOut, .cfNetServiceErrorTimeout:
            return "Timeout"
        default:
            return "Error"
        }
    }
}
