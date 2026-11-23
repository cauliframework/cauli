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

/// Switching florets on and off in the Cauli menu, and pausing Cauli,
/// while requests are intercepted on other threads.
final class FloretToggleTests: XCTestCase {

    private let interceptingFloretsSection = CauliViewController.Section.interceptingFlorets.rawValue

    /// A floret implemented as a struct, as custom florets may be.
    private struct CountingFloret: InterceptingFloret {
        final class Counter {
            var willRequestCalls = 0
        }

        var enabled = true
        let counter = Counter()

        func willRequest(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
            counter.willRequestCalls += 1
            completionHandler(record)
        }

        func didRespond(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
            completionHandler(record)
        }
    }

    // MARK: - Regression: switching off a struct floret

    func testSwitchingOffAStructFloretInTheMenuStopsCallingIt() throws {
        let floret = CountingFloret()
        let cauli = makeCauli([floret])
        let cell = try switchCell(in: makeMenu(cauli), row: 0)

        cell.switchValueChanged?(false)
        intercept(Record.fake(), with: cauli)

        XCTAssertEqual(floret.counter.willRequestCalls, 0, "the floret was switched off in the menu, but Cauli still calls it")
    }

    func testTheMenuShowsTheStateAStructFloretWasSwitchedTo() throws {
        let cauli = makeCauli([CountingFloret()])
        let sut = makeMenu(cauli)

        try switchCell(in: sut, row: 0).switchValueChanged?(false)

        let floret = try XCTUnwrap(cauli.florets.first as? InterceptingFloret)
        XCTAssertFalse(floret.enabled, "the floret Cauli uses must be switched off, not a copy of it")
    }

    // MARK: - Regression: data races (detected by the Thread Sanitizer)

    func testSwitchingFloretsAndPausingWhileRequestsAreIntercepted() throws {
        let cauli = makeCauli([FindReplaceFloret(name: "Switched on and off")])
        let cell = try switchCell(in: makeMenu(cauli), row: 0)
        let iterations = 200
        let intercepted = expectation(description: "all requests were intercepted")
        intercepted.expectedFulfillmentCount = iterations

        // The URL loading system calls Cauli on its own threads ...
        DispatchQueue.global().async {
            DispatchQueue.concurrentPerform(iterations: iterations) { _ in
                let record = Record.fake()
                _ = cauli.handles(record)
                cauli.willRequest(record) { _ in intercepted.fulfill() }
            }
        }
        // ... while the user switches florets on and off and the app pauses and resumes Cauli on the main thread.
        for iteration in 0..<iterations {
            let isOn = iteration.isMultiple(of: 2)
            cell.switchValueChanged?(isOn)
            if isOn {
                cauli.run()
            } else {
                cauli.pause()
            }
        }

        wait(for: [intercepted], timeout: 10)
    }

    // MARK: - Helper

    private func makeCauli(_ florets: [Floret]) -> Cauli {
        let cauli = Cauli(florets, configuration: Configuration(recordSelector: .all(), enableShakeGesture: false, storageCapacity: .records(1)))
        cauli.run()
        return cauli
    }

    private func makeMenu(_ cauli: Cauli) -> CauliViewController {
        let sut = CauliViewController(cauli: cauli)
        sut.loadViewIfNeeded()
        return sut
    }

    private func switchCell(in sut: CauliViewController, row: Int, file: StaticString = #filePath, line: UInt = #line) throws -> SwitchTableViewCell {
        let cell = sut.tableView(sut.tableView, cellForRowAt: IndexPath(row: row, section: interceptingFloretsSection))
        return try XCTUnwrap(cell as? SwitchTableViewCell, file: file, line: line)
    }

    /// Passes the record through Cauli on a background thread, like the URL loading system does.
    private func intercept(_ record: Record, with cauli: Cauli) {
        let intercepted = expectation(description: "the record was intercepted")
        DispatchQueue.global().async {
            cauli.willRequest(record) { _ in intercepted.fulfill() }
        }
        wait(for: [intercepted], timeout: 5)
    }
}
