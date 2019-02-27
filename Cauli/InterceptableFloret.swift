//
//  File.swift
//  Cauliframework
//
//  Created by Pascal Stüdlein on 27.02.19.
//

import Foundation

protocol InterceptableFloret: Floret {
    
    /// If a InterceptableFloret is disabled the both functions `willRequest` and `didRespond` will
    /// not be called anymore. A InterceptableFloret doesn't need to perform any specific action.
    var enabled: Bool { get set }
    
    /// This function will be called before a request is performed. The InterceptableFlorets will be
    /// called in the order the Cauli instance got initialized with.
    ///
    /// Using this function you can:
    /// - inspect the request
    /// - modify the request (update the `designatedRequest`)
    /// - fail the request (set the `result` to `.error()`)
    /// - return a cached or pre-calculated response (set the `result` to `.result()`)
    ///
    /// - Parameters:
    ///   - record: The `Record` that represents the request before it was performed.
    ///   - completionHandler: Call this completion handler exactly once with the
    ///     original or modified `Record`.
    func willRequest(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void)
    
    /// This function will be called after a request is performed and the response arrived.
    /// The InterceptableFlorets will be called in the order the Cauli instance got initialized with.
    ///
    /// Using this function you can:
    /// - modify the request
    ///
    /// - Parameters:
    ///   - record: The `Record` that represents the request after it was performed.
    ///   - completionHandler: Call this completion handler exactly once with the
    ///     original or modified `Record`.
    func didRespond(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void)
}
