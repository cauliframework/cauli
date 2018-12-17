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
            it("should call the willRequestReplacements") {
                var willRequestReplaceDefinitionCalled = false
                let replacer = FindReplaceFloret.ReplaceDefinition(modifier: { (record) -> (Record) in
                    willRequestReplaceDefinitionCalled = true
                    return record
                })
                
                let findReplaceFloret = FindReplaceFloret(willRequestReplacements: [replacer])
                findReplaceFloret.willRequest(Record.fake(), modificationCompletionHandler: { (_) in })
                expect(willRequestReplaceDefinitionCalled).toEventually(equal(true))
            }
            
            it("should not call the didRespondReplacements") {
                var didRespondReplaceDefinitionCalled = false
                let replacer = FindReplaceFloret.ReplaceDefinition(modifier: { (record) -> (Record) in
                    didRespondReplaceDefinitionCalled = true
                    return record
                })
                
                let findReplaceFloret = FindReplaceFloret(didRespondReplacements: [replacer])
                findReplaceFloret.willRequest(Record.fake(), modificationCompletionHandler: { (_) in })
                expect(didRespondReplaceDefinitionCalled).toEventually(equal(false))
            }
            
            it("should pass the modified Record of a ReplaceDefinition to the completionHandler") {
                let replaceDefinitionRecord = Record.fake(with: URL(string: "replace_definition_url")!)
                let replacer = FindReplaceFloret.ReplaceDefinition(modifier: { (record) -> (Record) in
                    return replaceDefinitionRecord
                })
                
                let findReplaceFloret = FindReplaceFloret(willRequestReplacements: [replacer])
                waitUntil { done in
                    findReplaceFloret.willRequest(Record.fake(), modificationCompletionHandler: { (record) in
                        expect(record.identifier) == replaceDefinitionRecord.identifier
                        done()
                    })
                }
            }
        }
        describe("didRespond(::") {
            it("should call the didRespondReplacements") {
                var didRespondReplaceDefinitionCalled = false
                let replacer = FindReplaceFloret.ReplaceDefinition(modifier: { (record) -> (Record) in
                    didRespondReplaceDefinitionCalled = true
                    return record
                })
                
                let findReplaceFloret = FindReplaceFloret(didRespondReplacements: [replacer])
                findReplaceFloret.didRespond(Record.fake(), modificationCompletionHandler: { (_) in })
                expect(didRespondReplaceDefinitionCalled).toEventually(equal(true))
            }
            
            it("should not call the willRequestReplacements") {
                var willRequestReplaceDefinitionCalled = false
                let replacer = FindReplaceFloret.ReplaceDefinition(modifier: { (record) -> (Record) in
                    willRequestReplaceDefinitionCalled = true
                    return record
                })
                
                let findReplaceFloret = FindReplaceFloret(willRequestReplacements: [replacer])
                findReplaceFloret.didRespond(Record.fake(), modificationCompletionHandler: { (_) in })
                expect(willRequestReplaceDefinitionCalled).toEventually(equal(false))
            }
            
            it("should pass the modified Record of a ReplaceDefinition to the completionHandler") {
                let replaceDefinitionRecord = Record.fake(with: URL(string: "replace_definition_url")!)
                let replacer = FindReplaceFloret.ReplaceDefinition(modifier: { (record) -> (Record) in
                    return replaceDefinitionRecord
                })
                
                let findReplaceFloret = FindReplaceFloret(didRespondReplacements: [replacer])
                waitUntil { done in
                    findReplaceFloret.didRespond(Record.fake(), modificationCompletionHandler: { (record) in
                        expect(record.identifier) == replaceDefinitionRecord.identifier
                        done()
                    })
                }
            }
        }
    }
}

