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

internal class SwitchTableViewCell: UITableViewCell {

    static let reuseIdentifier = "SwitchTableViewCell"
    static let nibName = "SwitchTableViewCell"

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var `switch`: UISwitch!
    var switchValueChanged: ((Bool) -> Void)?

    /// `isEnabled` false shows the row greyed out, with a switch that can't be changed.
    func set(title: String, switchValue: Bool, description: String?, isEnabled: Bool = true) {
        titleLabel.text = title
        descriptionLabel.text = description
        `switch`.isOn = switchValue
        `switch`.isEnabled = isEnabled
        titleLabel.isEnabled = isEnabled
        descriptionLabel.isEnabled = isEnabled
    }

    var isSwitchOn: Bool {
        `switch`.isOn
    }

    var isSwitchEnabled: Bool {
        `switch`.isEnabled
    }

    @IBAction private func switchValueChanged(_ sender: UISwitch) {
        switchValueChanged?(sender.isOn)
    }
}
