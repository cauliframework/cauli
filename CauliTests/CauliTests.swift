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
import Foundation
import XCTest

final class CauliTests: XCTestCase {

    // MARK: - init

    func testInitDoesNotCreateARetainCycle() {
        var strongCauli: Cauli? = Cauli([], configuration: Configuration.standard)
        weak var weakCauli: Cauli? = strongCauli
        strongCauli = nil
        XCTAssertNil(weakCauli)
    }

    func testInitUsesTheStandardConfigurationWhenNoParameterWasGiven() {
        let cauli = Cauli([])
        XCTAssertEqual(cauli.storage.capacity, Configuration.standard.storageCapacity)
    }

    func testInitConfiguresTheStorageWithTheCorrectStorageCapacity() {
        let cauli = Cauli([], configuration: Configuration(recordSelector: RecordSelector(selects: { _ in true }), enableShakeGesture: true, storageCapacity: .unlimited))
        XCTAssertEqual(cauli.storage.capacity, .unlimited)

        let cauli2 = Cauli([], configuration: Configuration(recordSelector: RecordSelector(selects: { _ in true }), enableShakeGesture: true, storageCapacity: .records(10)))
        XCTAssertEqual(cauli2.storage.capacity, .records(10))
    }

    // MARK: - isRunning

    func testIsNotRunningAfterInit() {
        let cauli = Cauli([], configuration: Configuration(recordSelector: .all(), enableShakeGesture: false, storageCapacity: .records(1)))
        XCTAssertFalse(cauli.isRunning)
    }

    func testIsRunningFollowsRunAndPause() {
        let cauli = Cauli([], configuration: Configuration(recordSelector: .all(), enableShakeGesture: false, storageCapacity: .records(1)))

        cauli.run()
        XCTAssertTrue(cauli.isRunning)

        cauli.pause()
        XCTAssertFalse(cauli.isRunning)
    }

    // MARK: - Regression: the main thread waiting for a request

    func testWillRequestCompletesWhileTheMainThreadWaitsForTheRequest() {
        assertCompletesWhileTheMainThreadIsBlocked { cauli, record, completion in
            cauli.willRequest(record, modificationCompletionHandler: completion)
        }
    }

    func testDidRespondCompletesWhileTheMainThreadWaitsForTheResponse() {
        assertCompletesWhileTheMainThreadIsBlocked { cauli, record, completion in
            cauli.didRespond(record, modificationCompletionHandler: completion)
        }
    }

    /// Calls `operation` on a background thread, like the URL loading system does, while the main thread
    /// blocks until it completes, like `Data(contentsOf:)` or a semaphore around a request in the app would.
    private func assertCompletesWhileTheMainThreadIsBlocked(file: StaticString = #filePath, line: UInt = #line, _ operation: @escaping (Cauli, Record, @escaping (Record) -> Void) -> Void) {
        let cauli = Cauli([], configuration: Configuration(recordSelector: .all(), enableShakeGesture: false, storageCapacity: .unlimited))
        cauli.run()
        let completed = DispatchSemaphore(value: 0)
        let eventuallyCompleted = expectation(description: "operation eventually completed")

        DispatchQueue.global().async {
            operation(cauli, Record.fake()) { _ in
                completed.signal()
                eventuallyCompleted.fulfill()
            }
        }

        // Normally this completes within milliseconds. A deadlock never resolves, so a generous timeout still
        // detects it, without failing when a busy CI simulator takes a few seconds to schedule the operation.
        let result = completed.wait(timeout: .now() + 10)
        XCTAssertEqual(result, .success, "deadlock: Cauli waits for the main thread, while the main thread waits for Cauli", file: file, line: line)

        // Clean up: stop handling records and let a pending `DispatchQueue.main.sync` run, so nothing leaks into other tests.
        cauli.pause()
        wait(for: [eventuallyCompleted], timeout: 5)
    }
}
