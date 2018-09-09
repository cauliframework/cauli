//
//  Storage.swift
//  Cauli
//
//  Created by Cornelius Horstmann on 18.07.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

public protocol Storage {

    /// Adds a record to the storage. Updates a possibly existing record.
    /// A record is the same if it's identifier is the same.
    ///
    /// - Parameter record: The record to add to the storage.
    func store(_ record: Record)

    /// Returns a number of records after the referenced record.
    /// Records are sorted by order there were added to the storage,
    /// Might return less than `count` if there are no more records.
    ///
    /// - Parameters:
    ///   - count: The number of records that should be returned.
    ///   - after: The record after which there should be new records returned.
    /// - Returns: The records after the referenced record.
    func records(_ count: Int, after: Record?) -> [Record]
}
