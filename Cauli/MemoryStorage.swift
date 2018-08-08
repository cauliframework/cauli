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
    
    init(capacity: Int = 30) {
        self.capacity = capacity
    }
    
    func store(_ record: Record) {
        assert(Thread.isMainThread, "\(#file):\(#line) must run on the main thread!")
        if let recordIndex = records.index(where: { $0.identifier == record.identifier }) {
            records[recordIndex] = record
        } else {
            records.append(record)
            if records.count > capacity {
                records.remove(at: 0)
            }
        }
    }
    
    func records(_ count: Int, after record: Record?) -> [Record] {
        assert(Thread.isMainThread, "\(#file):\(#line) must run on the main thread!")
        let index: Int
        if let record = record {
            index = records.index { $0.identifier == record.identifier } ?? 0
        } else {
            index = 0
        }
        let maxCount = max(count, records.count - index)
        return Array(records[index..<(index+maxCount)])
    }
}
