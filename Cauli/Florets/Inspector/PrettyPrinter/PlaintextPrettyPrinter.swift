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

internal class PlaintextPrettyPrinter: UIViewController {

    static var name = "Plaintext"

    private let string: String
    private let textView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    init(string: String) {
        self.string = string
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        view.addSubview(textView)
        view.addConstraints([
            NSLayoutConstraint(item: textView, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: textView, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: textView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: textView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0)
            ])

        textView.text = string
    }

}

extension PlaintextPrettyPrinter: PrettyPrinter {
    static func viewController(for item: Any) -> UIViewController? {
        switch item {
        case let string as String: return PlaintextPrettyPrinter(string: string)
        case let data as Data: return viewController(forJsonData: data)
        case let url as URL: return viewController(forUrl: url)
        default: return nil
        }
    }

    static func viewController(forUrl url: URL) -> UIViewController? {
        guard url.isFileURL, let data = try? Data(contentsOf: url) else {
            return nil
        }
        return viewController(forJsonData: data) ?? viewController(forPlaintextData: data)
    }

    static func viewController(forJsonData data: Data) -> UIViewController? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data),
            let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
            let jsonString = String(bytes: jsonData, encoding: .utf8) else { return nil }
        return PlaintextPrettyPrinter(string: jsonString)
    }

    static func viewController(forPlaintextData data: Data) -> UIViewController? {
        guard let string = String(bytes: data, encoding: .utf8) else { return nil }
        return PlaintextPrettyPrinter(string: string)
    }
}
