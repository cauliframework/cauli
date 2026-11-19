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

    private let displayingFloretsSection = 0
    private let interceptingFloretsSection = 1

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

    // MARK: - Helper

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
