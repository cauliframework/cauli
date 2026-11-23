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

/// Shows the totals of the network usage as a grid of tiles.
internal class NetworkUsageTotalsCell: UITableViewCell {

    static let reuseIdentifier = "NetworkUsageTotalsCell"

    /// One tile: e.g. "Received", "3.8 MB", "over the network".
    struct Tile {
        let label: String
        let value: String
        let detail: String
    }

    private let grid = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        grid.axis = .vertical
        grid.spacing = 10
        grid.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(grid)
        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: contentView.topAnchor),
            grid.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            grid.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            grid.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// The tiles, two per row.
    func set(tiles: [Tile]) {
        grid.arrangedSubviews.forEach { $0.removeFromSuperview() }
        stride(from: 0, to: tiles.count, by: 2).forEach { index in
            let row = UIStackView(arrangedSubviews: tiles[index..<min(index + 2, tiles.count)].map { NetworkUsageTotalsCell.view(for: $0) })
            row.spacing = 10
            row.distribution = .fillEqually
            grid.addArrangedSubview(row)
        }
    }

    private static func view(for tile: Tile) -> UIView {
        let label = makeLabel(tile.label, style: .footnote, color: .secondaryLabel)
        let value = makeLabel(tile.value, style: .title2, color: .label)
        value.font = UIFontMetrics(forTextStyle: .title2).scaledFont(for: .systemFont(ofSize: 22, weight: .semibold))
        let detail = makeLabel(tile.detail, style: .caption1, color: .secondaryLabel)
        let stack = UIStackView(arrangedSubviews: [label, value, detail])
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false

        let tileView = UIView()
        tileView.backgroundColor = .secondarySystemGroupedBackground
        tileView.layer.cornerRadius = 12
        tileView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: tileView.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: tileView.bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: tileView.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: tileView.trailingAnchor, constant: -14)
        ])
        tileView.isAccessibilityElement = true
        tileView.accessibilityLabel = "\(tile.label): \(tile.value), \(tile.detail)"
        return tileView
    }

    private static func makeLabel(_ text: String, style: UIFont.TextStyle, color: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: style)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = color
        label.numberOfLines = 0
        return label
    }
}
