//
//  MockFloret.swift
//  Cauli
//
//  Created by Cornelius Horstmann on 20.09.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

public class MockFloret: Floret {

    public var enabled: Bool = true

    public enum Mode {
        case record
        case mock
    }

    public var mode: Mode = .mock
    private lazy var recordStorage: MockFloretStorage = {
        MockFloretStorage.recorder()
    }()

    private lazy var mockStorage: MockFloretStorage? = {
        MockFloretStorage.mocker()
    }()

    public func willRequest(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) throws -> Void) {
        guard let storage = mockStorage else { try? completionHandler(record); return }
        if mode == .mock {
            try? completionHandler(storage.mockedRecord(record))
        } else {
            try? completionHandler(record)
        }
    }

    public func didRespond(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) throws -> Void) {
        if mode == .record {
            recordStorage.store(record)
        }
        try? completionHandler(record)
    }
}
