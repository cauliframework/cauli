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

final class CauliViewControllerTests: XCTestCase {

    private let cauliSection = CauliViewController.Section.cauli.rawValue
    private let displayingFloretsSection = CauliViewController.Section.displayingFlorets.rawValue
    private let interceptingFloretsSection = CauliViewController.Section.interceptingFlorets.rawValue

    // MARK: - Regression: florets that intercept and display

    func testListsTheMapRemoteFloretAsDisplayingFloret() {
        let floret = MapRemoteFloret(mappings: [mapping()])
        let sut = makeViewController(florets: [floret])

        XCTAssertEqual(sut.tableView(sut.tableView, numberOfRowsInSection: displayingFloretsSection), 1, "the mappings screen must be reachable from the Cauli menu")
        XCTAssertEqual(sut.tableView(sut.tableView, numberOfRowsInSection: interceptingFloretsSection), 1, "the floret must still be switchable on and off")
    }

    func testSelectingTheMapRemoteFloretShowsItsMappings() {
        let floret = MapRemoteFloret(mappings: [mapping()])
        let sut = makeViewController(florets: [floret])
        let navigationController = UINavigationController(rootViewController: sut)
        guard sut.tableView(sut.tableView, numberOfRowsInSection: displayingFloretsSection) > 0 else {
            return XCTFail("the MapRemoteFloret isn't listed as displaying floret, so its mappings can't be opened")
        }

        sut.tableView(sut.tableView, didSelectRowAt: IndexPath(row: 0, section: displayingFloretsSection))

        XCTAssertTrue(navigationController.topViewController is MappingsListViewController)
    }

    // MARK: - Pausing Cauli (#156)

    func testTheMenuShowsWhetherCauliInterceptsRequests() throws {
        let cauli = makeCauli(florets: [])
        cauli.pause()
        let sut = makeViewController(cauli: cauli)

        XCTAssertFalse(try interceptSwitch(in: sut).isSwitchOn)

        cauli.run()
        sut.tableView.reloadData()

        XCTAssertTrue(try interceptSwitch(in: sut).isSwitchOn)
    }

    func testTheInterceptSwitchPausesAndResumesCauli() throws {
        let cauli = makeCauli(florets: [])
        let sut = makeViewController(cauli: cauli)

        try interceptSwitch(in: sut).switchValueChanged?(false)
        XCTAssertFalse(cauli.isRunning)

        try interceptSwitch(in: sut).switchValueChanged?(true)
        XCTAssertTrue(cauli.isRunning)
    }

    func testWhilePausedTheInterceptingFloretsCantBeSwitched() throws {
        let cauli = makeCauli(florets: [NoCacheFloret()])
        let sut = makeViewController(cauli: cauli)
        XCTAssertTrue(try floretSwitch(in: sut).isSwitchEnabled)

        try interceptSwitch(in: sut).switchValueChanged?(false)

        XCTAssertFalse(try floretSwitch(in: sut).isSwitchEnabled, "switching florets has no effect while Cauli is paused")
    }

    func testWhilePausedTheDisplayingFloretsCanStillBeOpened() {
        let cauli = makeCauli(florets: [MapRemoteFloret(mappings: [mapping()])])
        cauli.pause()
        let sut = makeViewController(cauli: cauli)
        let navigationController = UINavigationController(rootViewController: sut)

        sut.tableView(sut.tableView, didSelectRowAt: IndexPath(row: 0, section: displayingFloretsSection))

        XCTAssertTrue(navigationController.topViewController is MappingsListViewController, "recorded requests must stay accessible while paused")
    }

    // MARK: - Onboarding without florets (#99)

    func testWithoutFloretsTheMenuExplainsHowToAddOne() throws {
        let sut = makeViewController(cauli: makeCauli(florets: []))

        let getStartedSection = try XCTUnwrap(sut.index(of: .getStarted), "a Cauli without florets must explain how to add one")
        let cell = sut.tableView(sut.tableView, cellForRowAt: IndexPath(row: 0, section: getStartedSection))
        XCTAssertTrue(cell is GetStartedTableViewCell)
        XCTAssertNil(sut.index(of: .displayingFlorets), "the empty floret sections are replaced")
        XCTAssertNil(sut.index(of: .interceptingFlorets), "the empty floret sections are replaced")
        XCTAssertNotNil(sut.index(of: .cauli), "Cauli can still be paused")
    }

    func testSelectingALearnMoreRowOpensTheDocumentation() throws {
        let sut = makeViewController(cauli: makeCauli(florets: []))
        var openedURLs: [URL] = []
        sut.openURL = { openedURLs.append($0) }
        let learnMoreSection = try XCTUnwrap(sut.index(of: .learnMore))
        XCTAssertEqual(sut.tableView(sut.tableView, numberOfRowsInSection: learnMoreSection), CauliViewController.learnMoreLinks.count)

        sut.tableView(sut.tableView, didSelectRowAt: IndexPath(row: 0, section: learnMoreSection))
        sut.tableView(sut.tableView, didSelectRowAt: IndexPath(row: 1, section: learnMoreSection))

        XCTAssertEqual(openedURLs.map(\.absoluteString), [
            "https://cauli.works/docs/florets.html",
            "https://cauli.works/docs/writing-your-own-plugin.html"
        ])
    }

    func testWithFloretsTheMenuShowsNoOnboarding() {
        let sut = makeViewController(cauli: makeCauli(florets: [InspectorFloret()]))

        XCTAssertNil(sut.index(of: .getStarted))
        XCTAssertNil(sut.index(of: .learnMore))
        XCTAssertEqual(sut.index(of: .displayingFlorets), displayingFloretsSection)
    }

    // MARK: - Helper

    private func makeCauli(florets: [Floret]) -> Cauli {
        let cauli = Cauli(florets, configuration: Configuration(recordSelector: .all(), enableShakeGesture: false, storageCapacity: .records(1)))
        cauli.run()
        return cauli
    }

    private func makeViewController(cauli: Cauli) -> CauliViewController {
        let sut = CauliViewController(cauli: cauli)
        sut.loadViewIfNeeded()
        return sut
    }

    private func interceptSwitch(in sut: CauliViewController) throws -> SwitchTableViewCell {
        try XCTUnwrap(sut.tableView(sut.tableView, cellForRowAt: IndexPath(row: 0, section: cauliSection)) as? SwitchTableViewCell)
    }

    private func floretSwitch(in sut: CauliViewController) throws -> SwitchTableViewCell {
        try XCTUnwrap(sut.tableView(sut.tableView, cellForRowAt: IndexPath(row: 0, section: interceptingFloretsSection)) as? SwitchTableViewCell)
    }

    private func makeViewController(florets: [Floret]) -> CauliViewController {
        let cauli = Cauli(florets, configuration: Configuration(recordSelector: .all(), enableShakeGesture: false, storageCapacity: .records(1)))
        let sut = CauliViewController(cauli: cauli)
        sut.loadViewIfNeeded()
        return sut
    }

    private func mapping() -> Mapping {
        Mapping(name: "map local", sourceLocation: MappingLocation(), destinationLocation: MappingLocation(host: "localhost"))
    }
}
