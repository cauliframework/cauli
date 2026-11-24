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

final class SecurityAuditScreenTests: XCTestCase {

    private let issuesSection = SecurityAuditViewController.Section.issues.rawValue
    private var suiteName = ""
    private var userDefaults = UserDefaults.standard

    override func setUp() {
        super.setUp()
        suiteName = "SecurityAuditScreenTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testTheFloretShowsItsFindingsInTheCauliMenu() {
        let floret = SecurityAuditFloret(userDefaults: userDefaults)
        let cauli = Cauli([floret], configuration: Configuration(recordSelector: .all(), enableShakeGesture: false, storageCapacity: .records(1)))

        XCTAssertTrue(floret.viewController(cauli) is SecurityAuditViewController)
        let menu = CauliViewController(cauli: cauli)
        menu.loadViewIfNeeded()
        XCTAssertEqual(menu.tableView(menu.tableView, numberOfRowsInSection: menu.index(of: .displayingFlorets) ?? -1), 1)
        XCTAssertEqual(menu.tableView(menu.tableView, numberOfRowsInSection: menu.index(of: .interceptingFlorets) ?? -1), 1)
    }

    func testTheListShowsTheFindingsByTheirSeverity() throws {
        let floret = makeFloret()
        let sut = makeList(floret)

        XCTAssertEqual(sut.tableView(sut.tableView, numberOfRowsInSection: issuesSection), 3)
        let first = try XCTUnwrap(cell(sut, row: 0, section: issuesSection) as? SecurityAuditIssueCell)
        XCTAssertEqual(first.badge.text, "CRITICAL")
        XCTAssertEqual(first.titleLabel.text, "Credentials over HTTP")
        XCTAssertEqual(first.detailLabel.text, "GET staging.example.com/me · 1×")
    }

    func testTheListExplainsWhenThereAreNoFindings() {
        let sut = makeList(SecurityAuditFloret(userDefaults: userDefaults))
        XCTAssertEqual(cell(sut, row: 0, section: issuesSection).textLabel?.text, "No findings yet")
    }

    func testAFindingShowsItsMaskedExample() throws {
        let floret = makeFloret()
        let sut = makeList(floret)
        let navigationController = UINavigationController(rootViewController: sut)

        sut.tableView(sut.tableView, didSelectRowAt: IndexPath(row: 0, section: issuesSection))
        let detail = try XCTUnwrap(navigationController.topViewController as? SecurityAuditIssueViewController)
        detail.loadViewIfNeeded()
        let example = SecurityAuditIssueViewController.Section.example.rawValue
        XCTAssertEqual(cell(detail, row: 0, section: example).textLabel?.text, "Authorization: Bearer abcd•••")

        detail.tableView(detail.tableView, didSelectRowAt: IndexPath(row: 1, section: example))
        XCTAssertTrue(detail.isRevealed)
        XCTAssertEqual(cell(detail, row: 0, section: example).textLabel?.text, "Authorization: Bearer abcdef123456")
    }

    func testIgnoringAFindingFromItsDetail() throws {
        let floret = makeFloret()
        let detail = SecurityAuditIssueViewController(floret: floret, issue: try XCTUnwrap(floret.issues.first))
        detail.loadViewIfNeeded()

        detail.tableView(detail.tableView, didSelectRowAt: IndexPath(row: 0, section: SecurityAuditIssueViewController.Section.ignore.rawValue))

        XCTAssertFalse(floret.issues.contains { $0.title == "Credentials over HTTP" })
        XCTAssertEqual(floret.ignoredFindings.map(\.title), ["Credentials over HTTP"])
    }

    func testSwipingIgnoresAFindingAndTheIgnoredListUndoesIt() throws {
        let floret = makeFloret()
        let sut = makeList(floret)
        let actions = try XCTUnwrap(sut.tableView(sut.tableView, trailingSwipeActionsConfigurationForRowAt: IndexPath(row: 0, section: issuesSection)))
        XCTAssertEqual(actions.actions.first?.title, "Ignore")

        sut.ignore(issueAt: 0)
        XCTAssertEqual(sut.issues.count, 2)
        XCTAssertEqual(cell(sut, row: 0, section: SecurityAuditViewController.Section.ignored.rawValue).detailTextLabel?.text, "1")

        let ignored = SecurityAuditIgnoredViewController(floret: floret)
        ignored.loadViewIfNeeded()
        ignored.reload()
        XCTAssertEqual(cell(ignored, row: 0, section: 0).detailTextLabel?.text, "GET staging.example.com/me")
        ignored.stopIgnoring(at: 0)
        XCTAssertEqual(cell(ignored, row: 0, section: 0).textLabel?.text, "Nothing ignored")
        XCTAssertEqual(floret.issues.count, 3)
    }

    func testResetEmptiesTheList() {
        let floret = makeFloret()
        let sut = makeList(floret)
        sut.resetTapped()
        XCTAssertEqual(cell(sut, row: 0, section: issuesSection).textLabel?.text, "No findings yet")
    }

    // MARK: - Helper

    /// Credentials over HTTP (critical), cleartext HTTP (warning) and a missing HSTS header (info).
    private func makeFloret() -> SecurityAuditFloret {
        let floret = SecurityAuditFloret(userDefaults: userDefaults)
        floret.audit(SecurityAuditFixture.exchange("http://staging.example.com/me", headers: ["Authorization": "Bearer abcdef123456"]))
        floret.audit(SecurityAuditFixture.exchange("https://api.example.com/feed", responseHeaders: [:]))
        return floret
    }

    private func makeList(_ floret: SecurityAuditFloret) -> SecurityAuditViewController {
        let sut = SecurityAuditViewController(floret: floret)
        sut.loadViewIfNeeded()
        sut.reload()
        return sut
    }

    private func cell(_ sut: UITableViewController, row: Int, section: Int) -> UITableViewCell {
        sut.tableView(sut.tableView, cellForRowAt: IndexPath(row: row, section: section))
    }
}
