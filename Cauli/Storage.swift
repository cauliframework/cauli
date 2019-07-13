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

import Foundation

/// A Storage is used to store and retrieve Records. It can be either in memory or on disk.
public protocol Storage {

    /// The `capacity` defines the capacity of the storage.
    var capacity: StorageCapacity { get set }

    /// A `RecordModifier` that can modify each `Record` before it is persisted to a `Storage`.
    /// This allows you to modify requests and responses after they are executed but before they are passed along to other florets.
    var preStorageRecordModifier: RecordModifier? { get set }

    /// Adds a record to the storage. Updates a possibly existing record.
    /// A record is the same if it's identifier is the same.
    ///
    /// - Parameter record: The record to add to the storage.
    func store(_ record: Record)

    /// Returns a number of records after the referenced record.
    ///
    /// - Parameters:
    ///   - predicate: An optional predicate to filter the records
    ///   - sorting: A sort descriptor defining the order of the returned items
    ///   - limit: The maximum number of records that should be returned.
    ///   - after: The record after which there should be new records returned.
    ///         If nil, the first records are returned
    /// - Returns: The records after the referenced record.
    func records<T: Comparable>(with predicate: NSPredicate?, sortedBy keyPath: KeyPath<Record, T?>, ascending: Bool, limit: Int, after record: Record?) -> [Record]
}

extension Storage {
    func records(limit: Int, after record: Record? = nil) -> [Record] {
        return records(with: nil, sortedBy: \Record.requestStarted, ascending: true, limit: limit, after: record)
    }
}

/// Defines the capacity of a storage.
public enum StorageCapacity: Equatable {
    /// The capacity is unlimited.
    case unlimited
    /// The capacity is limited to a certain number of records.
    case records(Int)
}
