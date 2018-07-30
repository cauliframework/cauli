//
//  MemoryStorage.swift
//  Cauli
//
//  Created by Cornelius Horstmann on 30.07.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

final class MemoryStorage: Storage {
    
    let capacity: Int
    var records: [Record] = []
    var memoryWarningObserver: NSObjectProtocol?
    
    init(capacity: Int = 30) {
        self.capacity = capacity
        memoryWarningObserver = NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification, object: UIApplication.shared, queue: nil) { [weak self] notification in
            guard let strongself = self else { return }
            let index = max(0, strongself.records.count - capacity)
            strongself.records = Array(strongself.records[index..<(index+capacity)])
        }
    }
    
    func store(_ record: Record) {
        assert(Thread.isMainThread, "\(#file):\(#line) must run on the main thread!")
        if records.contains(where: { $0.identifier == record.identifier }) {
            records = records.cauli_replacing(with: record, where: { $0.identifier == record.identifier })
        } else {
            records.append(record)
        }
    }
    
    func records(_ count: Int, after record: Record?) -> [Record] {
        assert(Thread.isMainThread, "\(#file):\(#line) must run on the main thread!")
        let index: Int
        if let record = record {
            index = records.firstIndex { $0.identifier == record.identifier } ?? 0
        } else {
            index = 0
        }
        let maxCount = max(count, records.count - index)
        return Array(records[index..<(index+maxCount)])
    }
}

internal extension Array {
    func cauli_replacing(with replacement: Element, where predicate: (Element) throws -> Bool) rethrows -> [Element] {
        return try map {
            if try predicate($0) {
                return replacement
            } else {
                return $0
            }
        }
    }
}
