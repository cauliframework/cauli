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

/// The number of findings per severity, side by side.
internal class SecurityAuditTotalsCell: UITableViewCell {

    static let reuseIdentifier = "SecurityAuditTotalsCell"

    private let row = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        row.distribution = .fillEqually
        row.spacing = 8
        row.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// The number of issues per severity, the most serious first.
    func set(counts: [(severity: SecurityAuditSeverity, count: Int)]) {
        row.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (severity, number) in counts {
            let value = UILabel()
            value.text = "\(number)"
            value.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .title2).pointSize, weight: .bold)
            value.textColor = number < 1 ? .secondaryLabel : SecurityAuditFormatting.color(of: severity)
            let label = UILabel()
            label.text = severity == .warning ? "Warnings" : severity.name
            label.font = .preferredFont(forTextStyle: .footnote)
            label.textColor = .secondaryLabel
            [value, label].forEach { $0.adjustsFontForContentSizeCategory = true }
            let tile = UIStackView(arrangedSubviews: [value, label])
            tile.axis = .vertical
            tile.spacing = 2
            tile.isAccessibilityElement = true
            tile.accessibilityLabel = "\(number) \(label.text ?? "")"
            row.addArrangedSubview(tile)
        }
    }
}
