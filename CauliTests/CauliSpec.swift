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

import Cauliframework
import Foundation
import Quick
import Nimble

class CauliSpec: QuickSpec {
    override func spec() {
        describe("init") {
            it("should not create a retain cycle") {
                var strongCauli: Cauli? = Cauli([], configuration: Configuration.standard)
                weak var weakCauli: Cauli? = strongCauli
                strongCauli = nil
                expect(weakCauli).to(beNil())
            }
            it("should initialize with standard configuration when no parameter was given") {
                let cauli = Cauli([])
                let standardConfiguration = Configuration.standard
                expect(cauli.storage.capacity) == standardConfiguration.storageCapacity
            }
            it("should configure the storage with the correct storage capacity") {
                let cauli = Cauli([], configuration: Configuration(recordSelector: RecordSelector.init(selects: {_ in true }), enableShakeGesture: true, storageCapacity: .unlimited))
                expect(cauli.storage.capacity) == .unlimited
                
                let cauli2 = Cauli([], configuration: Configuration(recordSelector: RecordSelector.init(selects: {_ in true }), enableShakeGesture: true, storageCapacity: .records(10)))
                expect(cauli2.storage.capacity) == .records(10)
            }
        }
    }
}
