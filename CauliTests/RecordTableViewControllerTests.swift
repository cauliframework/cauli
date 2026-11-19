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

/// On iPad, action sheets and activity view controllers are presented as popovers
/// and UIKit raises an exception if they have neither a source view nor a bar button item.
final class RecordTableViewControllerTests: XCTestCase {

    private final class PresentationCapturingRecordTableViewController: RecordTableViewController {
        var presentedControllers: [UIViewController] = []

        override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
            presentedControllers.append(viewControllerToPresent)
        }
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "Popovers only need an anchor on iPad.")
    }

    // MARK: - Regression: popovers without an anchor

    func testTheShareButtonAnchorsTheShareSheet() throws {
        let sut = makeViewController()

        sut.shareButtonTapped()

        let shareSheet = try XCTUnwrap(sut.presentedControllers.last as? UIActivityViewController)
        assertHasPopoverAnchor(shareSheet)
    }

    func testSelectingARowAnchorsTheActionSheet() throws {
        let sut = makeViewController()
        let headerFieldsRow = IndexPath(row: 2, section: 0)
        XCTAssertNotNil(sut.tableView.cellForRow(at: headerFieldsRow), "the row must be laid out to be selectable")

        sut.tableView(sut.tableView, didSelectRowAt: headerFieldsRow)

        let actionSheet = try XCTUnwrap(sut.presentedControllers.last as? UIAlertController)
        assertHasPopoverAnchor(actionSheet)
    }

    // MARK: - Helper

    private func makeViewController() -> PresentationCapturingRecordTableViewController {
        var request = URLRequest(url: URL(string: "https://cauli.works")!)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let sut = PresentationCapturingRecordTableViewController(Record(request))
        sut.loadViewIfNeeded()
        sut.view.frame = CGRect(x: 0, y: 0, width: 768, height: 1024)
        sut.tableView.reloadData()
        sut.tableView.layoutIfNeeded()
        return sut
    }

    private func assertHasPopoverAnchor(_ viewController: UIViewController, file: StaticString = #filePath, line: UInt = #line) {
        guard let popover = viewController.popoverPresentationController else {
            return XCTFail("expected \(type(of: viewController)) to be presented as a popover on iPad", file: file, line: line)
        }
        XCTAssertTrue(popover.sourceView != nil || popover.barButtonItem != nil,
                      "\(type(of: viewController)) needs a sourceView or barButtonItem, otherwise UIKit raises an exception on iPad",
                      file: file, line: line)
    }
}

final class RecordTableViewControllerActionTests: XCTestCase {

    private final class PresentationCapturingRecordTableViewController: RecordTableViewController {
        var presentedControllers: [UIViewController] = []

        override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
            presentedControllers.append(viewControllerToPresent)
        }
    }

    func testSelectingTheCURLRowOffersToCopyIt() throws {
        let sut = PresentationCapturingRecordTableViewController(Record(URLRequest(url: URL(string: "https://cauli.works")!)))
        sut.loadViewIfNeeded()
        sut.view.frame = CGRect(x: 0, y: 0, width: 768, height: 1024)
        sut.tableView.reloadData()
        sut.tableView.layoutIfNeeded()
        let cURLRow = try XCTUnwrap(sut.datasource.sections.first?.items.firstIndex { $0.title == "cURL" })
        let indexPath = IndexPath(row: cURLRow, section: 0)
        sut.tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
        sut.tableView.layoutIfNeeded()
        XCTAssertNotNil(sut.tableView.cellForRow(at: indexPath), "the row must be laid out to be selectable")

        sut.tableView(sut.tableView, didSelectRowAt: indexPath)

        let actionSheet = try XCTUnwrap(sut.presentedControllers.last as? UIAlertController)
        XCTAssertTrue(actionSheet.actions.contains { $0.title == "Copy" })
    }
}
