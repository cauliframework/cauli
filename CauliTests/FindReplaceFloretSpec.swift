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

@testable import Cauli
import Foundation
import Quick
import Nimble

class FindReplaceFloretSpec: QuickSpec {
    override func spec() {
        describe("init") {
            it("should remember the Floret name") {
                let findReplaceFloret = FindReplaceFloret(name: "FindReplaceFloretSpecs")
                expect(findReplaceFloret.name) == "FindReplaceFloretSpecs"
            }
        }
        describe("willRequest(::") {
            it("should call the willRequestModifiers") {
                var willRequestRecordModifierCalled = false
                let modifier = FindReplaceFloret.RecordModifier(modify: { (record) -> (Record) in
                    willRequestRecordModifierCalled = true
                    return record
                })
                
                let findReplaceFloret = FindReplaceFloret(willRequestModifiers: [modifier])
                findReplaceFloret.willRequest(Record.fake(), modificationCompletionHandler: { (_) in })
                expect(willRequestRecordModifierCalled).toEventually(equal(true))
            }
            
            it("should not call the didRespondModifiers") {
                var didRespondRecordModifierCalled = false
                let modifier = FindReplaceFloret.RecordModifier(modify: { (record) -> (Record) in
                    didRespondRecordModifierCalled = true
                    return record
                })
                
                let findReplaceFloret = FindReplaceFloret(didRespondModifiers: [modifier])
                findReplaceFloret.willRequest(Record.fake(), modificationCompletionHandler: { (_) in })
                expect(didRespondRecordModifierCalled).toEventually(equal(false))
            }
            
            it("should pass the modified Record of a RecordModifier to the completionHandler") {
                let recordModifierRecord = Record.fake(with: URL(string: "replace_definition_url")!)
                let modifier = FindReplaceFloret.RecordModifier(modify: { (record) -> (Record) in
                    return recordModifierRecord
                })
                
                let findReplaceFloret = FindReplaceFloret(willRequestModifiers: [modifier])
                waitUntil { done in
                    findReplaceFloret.willRequest(Record.fake(), modificationCompletionHandler: { (record) in
                        expect(record.identifier) == recordModifierRecord.identifier
                        done()
                    })
                }
            }
        }
        describe("didRespond(::") {
            it("should call the didRespondModifiers") {
                var didRespondRecordModifierCalled = false
                let modifier = FindReplaceFloret.RecordModifier(modify: { (record) -> (Record) in
                    didRespondRecordModifierCalled = true
                    return record
                })
                
                let findReplaceFloret = FindReplaceFloret(didRespondModifiers: [modifier])
                findReplaceFloret.didRespond(Record.fake(), modificationCompletionHandler: { (_) in })
                expect(didRespondRecordModifierCalled).toEventually(equal(true))
            }
            
            it("should not call the willRequestModifiers") {
                var willRequestRecordModifierCalled = false
                let modifier = FindReplaceFloret.RecordModifier(modify: { (record) -> (Record) in
                    willRequestRecordModifierCalled = true
                    return record
                })
                
                let findReplaceFloret = FindReplaceFloret(willRequestModifiers: [modifier])
                findReplaceFloret.didRespond(Record.fake(), modificationCompletionHandler: { (_) in })
                expect(willRequestRecordModifierCalled).toEventually(equal(false))
            }
            
            it("should pass the modified Record of a RecordModifier to the completionHandler") {
                let recordModifierRecord = Record.fake(with: URL(string: "replace_definition_url")!)
                let modifier = FindReplaceFloret.RecordModifier(modify: { (record) -> (Record) in
                    return recordModifierRecord
                })
                
                let findReplaceFloret = FindReplaceFloret(didRespondModifiers: [modifier])
                waitUntil { done in
                    findReplaceFloret.didRespond(Record.fake(), modificationCompletionHandler: { (record) in
                        expect(record.identifier) == recordModifierRecord.identifier
                        done()
                    })
                }
            }
        }
    }
}

