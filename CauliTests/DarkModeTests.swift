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

@testable import Cauliframework
import UIKit
import XCTest

/// Cauli's screens must stay readable in dark mode,
/// so nothing may draw a light background where the system draws a dark one.
final class DarkModeTests: XCTestCase {

    private let dark = UITraitCollection(userInterfaceStyle: .dark)

    // MARK: - Regression: light backgrounds in dark mode

    func testThePlaintextViewerHasADarkBackground() throws {
        let sut = PlaintextPrettyPrinter(string: "{ \"florets\": [] }")
        sut.loadViewIfNeeded()

        assertIsNotLight(sut.view.backgroundColor, "the background of the plaintext viewer")
    }

    func testTheFloretSwitchCellHasNoLightBackgrounds() throws {
        let nib = UINib(nibName: SwitchTableViewCell.nibName, bundle: Cauli.bundle)
        let cell = try XCTUnwrap(nib.instantiate(withOwner: nil).first as? SwitchTableViewCell)
        cell.set(title: "MockFloret", switchValue: true, description: "Answers requests with stored responses.")

        for view in viewsOutsideOfControls(in: cell.contentView) {
            assertIsNotLight(view.backgroundColor, "the background of \(view)")
        }
    }

    // MARK: - Helper

    /// All views in the hierarchy, without the internals of controls like `UISwitch`,
    /// which are drawn by UIKit and adapt on their own.
    private func viewsOutsideOfControls(in view: UIView) -> [UIView] {
        guard !(view is UIControl) else { return [] }
        return [view] + view.subviews.flatMap { viewsOutsideOfControls(in: $0) }
    }

    private func assertIsNotLight(_ color: UIColor?, _ description: String, file: StaticString = #filePath, line: UInt = #line) {
        guard let color = color?.resolvedColor(with: dark) else { return } // no color draws nothing
        var white: CGFloat = 0
        var alpha: CGFloat = 0
        guard color.getWhite(&white, alpha: &alpha) else {
            return XCTFail("\(description) has a color that can't be checked: \(color)", file: file, line: line)
        }
        XCTAssertFalse(alpha > 0.1 && white > 0.5, "\(description) is light in dark mode: \(color)", file: file, line: line)
    }
}
