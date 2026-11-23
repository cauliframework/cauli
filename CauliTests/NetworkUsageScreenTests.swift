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

final class NetworkUsageScreenTests: XCTestCase {

    private let hintsSection = NetworkUsageViewController.Section.hints.rawValue
    private let hostsSection = NetworkUsageViewController.Section.hosts.rawValue

    func testTheFloretShowsItsOverviewInTheCauliMenu() {
        let floret = NetworkUsageFloret()
        let cauli = Cauli([floret], configuration: Configuration(recordSelector: .all(), enableShakeGesture: false, storageCapacity: .records(1)))

        XCTAssertTrue(floret.viewController(cauli) is NetworkUsageViewController)
        let menu = CauliViewController(cauli: cauli)
        menu.loadViewIfNeeded()
        XCTAssertNotNil(menu.index(of: .displayingFlorets))
        XCTAssertEqual(menu.tableView(menu.tableView, numberOfRowsInSection: menu.index(of: .displayingFlorets) ?? -1), 1, "the overview must be reachable")
        XCTAssertEqual(menu.tableView(menu.tableView, numberOfRowsInSection: menu.index(of: .interceptingFlorets) ?? -1), 1, "the floret can be switched off")
    }

    func testTheOverviewListsTheHintsAndHosts() {
        let floret = NetworkUsageFloret()
        respond(NetworkUsageFixture.record(url: "https://api.example.com/users/1", body: 50_000), to: floret)
        respond(NetworkUsageFixture.record(url: "https://images.example.com/a.png", headers: ["Content-Type": "image/png"], body: 10_000), to: floret)

        let sut = makeOverview(floret)

        XCTAssertEqual(sut.tableView(sut.tableView, numberOfRowsInSection: hintsSection), floret.hints.count)
        XCTAssertEqual(sut.tableView(sut.tableView, numberOfRowsInSection: hostsSection), 2)
        XCTAssertEqual(cellText(sut, row: 0, section: hostsSection), "api.example.com", "the host receiving the most bytes comes first")
    }

    func testAHintOfACustomRuleOpensItsDetail() throws {
        let floret = NetworkUsageFloret(rules: [CustomRule()])
        respond(NetworkUsageFixture.record(url: "https://api.example.com/users/1"), to: floret)
        let sut = makeOverview(floret)
        let navigationController = UINavigationController(rootViewController: sut)

        XCTAssertEqual(cellText(sut, row: 0, section: hintsSection), "Custom hint")
        sut.tableView(sut.tableView, didSelectRowAt: IndexPath(row: 0, section: hintsSection))

        let detail = try XCTUnwrap(navigationController.topViewController as? NetworkUsageHintViewController)
        XCTAssertEqual(detail.hint.ruleIdentifier, "custom")
        detail.loadViewIfNeeded()
        XCTAssertEqual(detail.tableView(detail.tableView, numberOfRowsInSection: NetworkUsageHintViewController.Section.endpoints.rawValue), 1)
    }

    func testAHostOpensItsEndpointsTaggedWithTheirHints() throws {
        let floret = NetworkUsageFloret()
        respond(NetworkUsageFixture.record(url: "https://api.example.com/users/1", body: 50_000), to: floret)
        let sut = makeOverview(floret)
        let navigationController = UINavigationController(rootViewController: sut)

        sut.tableView(sut.tableView, didSelectRowAt: IndexPath(row: 0, section: hostsSection))

        let detail = try XCTUnwrap(navigationController.topViewController as? NetworkUsageHostViewController)
        XCTAssertEqual(detail.endpoints.map(\.name), ["GET /users/:id"])
        XCTAssertEqual(detail.hintTitles(for: try XCTUnwrap(detail.endpoints.first)), ["Uncompressed responses"])
    }

    func testResetEmptiesTheOverview() {
        let floret = NetworkUsageFloret()
        respond(NetworkUsageFixture.record(url: "https://api.example.com/users/1", body: 50_000), to: floret)
        let sut = makeOverview(floret)

        sut.resetTapped()

        XCTAssertEqual(sut.usage.totals.requests, 0)
        XCTAssertTrue(sut.hints.isEmpty)
        XCTAssertEqual(cellText(sut, row: 0, section: hostsSection), "No requests yet")
        XCTAssertEqual(cellText(sut, row: 0, section: hintsSection), "No hints yet")
    }

    // MARK: - Helper

    private struct CustomRule: NetworkUsageRule {
        let identifier = "custom"
        func evaluate(_ usage: NetworkUsageSnapshot) -> NetworkUsageHint? {
            NetworkUsageHint(ruleIdentifier: identifier, severity: .info, title: "Custom hint", summary: "found by a custom rule", affectedEndpoints: usage.endpoints, estimatedSavingBytes: 1_000, howToFix: "Fix it.")
        }
    }

    private func makeOverview(_ floret: NetworkUsageFloret) -> NetworkUsageViewController {
        let sut = NetworkUsageViewController(floret: floret)
        sut.loadViewIfNeeded()
        sut.reload()
        return sut
    }

    private func cellText(_ sut: UITableViewController, row: Int, section: Int) -> String? {
        sut.tableView(sut.tableView, cellForRowAt: IndexPath(row: row, section: section)).textLabel?.text
    }

    private func respond(_ record: Record, to floret: NetworkUsageFloret) {
        floret.didRespond(record) { _ in }
    }
}
