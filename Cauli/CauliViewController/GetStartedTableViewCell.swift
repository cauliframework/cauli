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

/// Shown in the Cauli menu while a Cauli instance has no florets: explains what florets are
/// and how to add one.
internal class GetStartedTableViewCell: UITableViewCell {

    static let reuseIdentifier = "GetStartedTableViewCell"
    static let codeExample = "let cauli = Cauli([InspectorFloret()])\ncauli.run()"

    let titleLabel = UILabel()
    let bodyLabel = UILabel()
    let codeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        selectionStyle = .none

        let iconView = UIImageView(image: UIImage(systemName: "square.stack.3d.up"))
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.isAccessibilityElement = false

        titleLabel.text = "Add your first floret"
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        titleLabel.accessibilityTraits = .header

        let titleStack = UIStackView(arrangedSubviews: [iconView, titleLabel])
        titleStack.spacing = 12
        titleStack.alignment = .center

        bodyLabel.text = "Florets are Cauli's plugins. Displaying florets show what Cauli recorded, intercepting florets change requests and responses. This Cauli has none yet."
        bodyLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        bodyLabel.adjustsFontForContentSizeCategory = true
        bodyLabel.numberOfLines = 0

        codeLabel.text = GetStartedTableViewCell.codeExample
        codeLabel.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: .monospacedSystemFont(ofSize: 13, weight: .regular))
        codeLabel.adjustsFontForContentSizeCategory = true
        codeLabel.numberOfLines = 0
        codeLabel.accessibilityLabel = "Example: \(GetStartedTableViewCell.codeExample)"

        let codeBackground = UIView()
        codeBackground.backgroundColor = .tertiarySystemFill
        codeBackground.layer.cornerRadius = 8
        codeLabel.translatesAutoresizingMaskIntoConstraints = false
        codeBackground.addSubview(codeLabel)
        NSLayoutConstraint.activate([
            codeLabel.topAnchor.constraint(equalTo: codeBackground.topAnchor, constant: 10),
            codeLabel.bottomAnchor.constraint(equalTo: codeBackground.bottomAnchor, constant: -10),
            codeLabel.leadingAnchor.constraint(equalTo: codeBackground.leadingAnchor, constant: 12),
            codeLabel.trailingAnchor.constraint(equalTo: codeBackground.trailingAnchor, constant: -12)
        ])

        let stack = UIStackView(arrangedSubviews: [titleStack, bodyLabel, codeBackground])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor, constant: -8),
            stack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor)
        ])
    }
}
