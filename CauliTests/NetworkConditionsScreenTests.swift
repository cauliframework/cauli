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

final class NetworkConditionsScreenTests: XCTestCase {

    private let hostsSection = NetworkConditionsViewController.Section.hosts.rawValue
    private var suiteName = ""
    private var userDefaults = UserDefaults.standard

    override func setUp() {
        super.setUp()
        suiteName = "NetworkConditionsScreenTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testTheFloretShowsItsConditionsInTheCauliMenu() {
        let floret = NetworkConditionsFloret(userDefaults: userDefaults)
        let cauli = Cauli([floret], configuration: Configuration(recordSelector: .all(), enableShakeGesture: false, storageCapacity: .records(1)))

        XCTAssertTrue(floret.viewController(cauli) is NetworkConditionsViewController)
        let menu = CauliViewController(cauli: cauli)
        menu.loadViewIfNeeded()
        XCTAssertEqual(menu.tableView(menu.tableView, numberOfRowsInSection: menu.index(of: .displayingFlorets) ?? -1), 1)
        XCTAssertEqual(menu.tableView(menu.tableView, numberOfRowsInSection: menu.index(of: .interceptingFlorets) ?? -1), 1)
    }

    func testTheListShowsTheHostsWithTheirConditions() {
        let floret = makeFloret(hosts: ["images.example.com", "api.example.com"])
        floret.setCondition(.edge, for: "api.example.com")
        let sut = makeList(floret)

        XCTAssertEqual(sut.tableView(sut.tableView, numberOfRowsInSection: hostsSection), 2)
        let first = cell(sut, row: 0, section: hostsSection)
        XCTAssertEqual(first.textLabel?.text, "api.example.com", "the most recently used host comes first")
        XCTAssertEqual(first.detailTextLabel?.text, "400 ms · 240 / 200 kbit/s")
        XCTAssertEqual(first.accessibilityValue, "Edge")
        let second = cell(sut, row: 1, section: hostsSection)
        XCTAssertEqual(second.detailTextLabel?.text, "Uses the default")
        XCTAssertEqual(second.accessibilityValue, "Default")
    }

    func testTheListExplainsWhenThereAreNoHosts() {
        let sut = makeList(makeFloret(hosts: []))
        XCTAssertEqual(sut.tableView(sut.tableView, numberOfRowsInSection: hostsSection), 1)
        XCTAssertEqual(cell(sut, row: 0, section: hostsSection).textLabel?.text, "No hosts yet")
    }

    func testPickingAConditionForAHost() throws {
        let floret = makeFloret(hosts: ["api.example.com"])
        let sut = makeList(floret)
        let navigationController = UINavigationController(rootViewController: sut)

        sut.tableView(sut.tableView, didSelectRowAt: IndexPath(row: 0, section: hostsSection))
        let picker = try XCTUnwrap(navigationController.topViewController as? NetworkConditionPickerViewController)
        picker.loadViewIfNeeded()
        XCTAssertEqual(picker.host, "api.example.com")
        XCTAssertNil(picker.selectedCondition, "the host uses the default")

        let presets = NetworkConditionPickerViewController.Section.presets.rawValue
        let edge = try XCTUnwrap(picker.presets.firstIndex(of: .edge))
        picker.tableView(picker.tableView, didSelectRowAt: IndexPath(row: edge, section: presets))
        XCTAssertEqual(floret.condition(for: "api.example.com"), .edge)
        XCTAssertEqual(picker.tableView(picker.tableView, cellForRowAt: IndexPath(row: edge, section: presets)).accessoryType, .checkmark)

        picker.tableView(picker.tableView, didSelectRowAt: IndexPath(row: 0, section: NetworkConditionPickerViewController.Section.useDefault.rawValue))
        XCTAssertNil(floret.condition(for: "api.example.com"))
    }

    func testPickingTheDefaultCondition() throws {
        let floret = makeFloret(hosts: [])
        let sut = makeList(floret)
        let navigationController = UINavigationController(rootViewController: sut)

        sut.tableView(sut.tableView, didSelectRowAt: IndexPath(row: 0, section: NetworkConditionsViewController.Section.defaultCondition.rawValue))
        let picker = try XCTUnwrap(navigationController.topViewController as? NetworkConditionPickerViewController)
        picker.loadViewIfNeeded()
        XCTAssertNil(picker.host)
        XCTAssertEqual(picker.tableView(picker.tableView, numberOfRowsInSection: NetworkConditionPickerViewController.Section.useDefault.rawValue), 0)

        let threeG = try XCTUnwrap(picker.presets.firstIndex(of: .threeG))
        picker.tableView(picker.tableView, didSelectRowAt: IndexPath(row: threeG, section: NetworkConditionPickerViewController.Section.presets.rawValue))
        XCTAssertEqual(floret.defaultCondition, .threeG)
    }

    func testCustomConditionsHaveTheirOwnSection() {
        let custom = NetworkCondition(name: "Slow API", latency: 2, downloadBytesPerSecond: 20_000, uploadBytesPerSecond: 20_000, failureRate: 0.2, failure: .httpStatus(503))
        let floret = NetworkConditionsFloret(conditions: NetworkCondition.presets + [custom], userDefaults: userDefaults)
        let picker = NetworkConditionPickerViewController(floret: floret, host: nil)
        picker.loadViewIfNeeded()

        XCTAssertEqual(picker.presets, NetworkCondition.presets)
        XCTAssertEqual(picker.customConditions, [custom])
        let row = cell(picker, row: 0, section: NetworkConditionPickerViewController.Section.custom.rawValue)
        XCTAssertEqual(row.textLabel?.text, "Slow API")
        XCTAssertEqual(row.detailTextLabel?.text, "2 s · 160 / 160 kbit/s · 20% HTTP 503")
    }

    func testStopAllThrottlingKeepsTheHosts() {
        let floret = makeFloret(hosts: ["api.example.com"])
        floret.defaultCondition = .edge
        floret.setCondition(.offline, for: "api.example.com")
        let sut = makeList(floret)

        sut.tableView(sut.tableView, didSelectRowAt: IndexPath(row: 0, section: NetworkConditionsViewController.Section.stopAll.rawValue))

        XCTAssertEqual(floret.defaultCondition, .noThrottling)
        XCTAssertNil(floret.condition(for: "api.example.com"))
        XCTAssertEqual(sut.hosts, ["api.example.com"])
    }

    func testSwipingForgetsAHost() throws {
        let floret = makeFloret(hosts: ["images.example.com", "api.example.com"])
        let sut = makeList(floret)
        let actions = try XCTUnwrap(sut.tableView(sut.tableView, trailingSwipeActionsConfigurationForRowAt: IndexPath(row: 0, section: hostsSection)))
        XCTAssertEqual(actions.actions.first?.title, "Forget")

        sut.forget(hostAt: 0)

        XCTAssertEqual(sut.hosts, ["images.example.com"])
        XCTAssertEqual(floret.hosts, ["images.example.com"])
    }

    func testThePresetsAreDescribed() {
        XCTAssertEqual(NetworkCondition.presets.map(NetworkConditionFormatting.details), [
            "Requests are passed on unchanged",
            "50 ms · 50 / 10 Mbit/s",
            "100 ms · 780 / 330 kbit/s",
            "400 ms · 240 / 200 kbit/s",
            "500 ms · 1 / 1 Mbit/s · 10% connection lost",
            "All requests fail: not connected"
        ])
        XCTAssertEqual(NetworkConditionFormatting.bandwidth(download: 6_250_000, upload: 25_000), "50 Mbit/s / 200 kbit/s")
        XCTAssertEqual(NetworkConditionFormatting.bandwidth(download: 30_000, upload: nil), "240 kbit/s down")
    }

    // MARK: - Helper

    /// A floret that remembers the hosts, the first one most recently used.
    private func makeFloret(hosts: [String]) -> NetworkConditionsFloret {
        let floret = NetworkConditionsFloret(userDefaults: userDefaults)
        for host in hosts.reversed() {
            floret.willRequest(Record(URLRequest(url: URL(string: "https://\(host)/")!))) { _ in }
        }
        return floret
    }

    private func makeList(_ floret: NetworkConditionsFloret) -> NetworkConditionsViewController {
        let sut = NetworkConditionsViewController(floret: floret)
        sut.loadViewIfNeeded()
        sut.reload()
        return sut
    }

    private func cell(_ sut: UITableViewController, row: Int, section: Int) -> UITableViewCell {
        sut.tableView(sut.tableView, cellForRowAt: IndexPath(row: row, section: section))
    }
}
