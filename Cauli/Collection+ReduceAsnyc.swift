//
//  Collection+ReduceAsnyc.swift
//  Cauli
//
//  Created by Cornelius Horstmann on 11.09.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

internal extension Collection {

    typealias AsynchTransformation<Product> = (Product, Element, @escaping (Product) -> Void) -> Void

    func cauli_reduceAsync<Product>(_ initial: Product, transform: @escaping AsynchTransformation<Product>, completion: @escaping (Product) -> Void) {
        cauli_reduceAsync(initial, transform: transform, completion: completion, index: startIndex)
    }

    fileprivate func cauli_reduceAsync<Product>(_ initial: Product, transform: @escaping AsynchTransformation<Product>, completion: @escaping (Product) -> Void, index: Index) {
        guard index <= endIndex else { return completion(initial) }
        let element = self[index]
        transform(initial, element) { result in
            let nextIndex = self.index(after: index)
            self.cauli_reduceAsync(result, transform: transform, completion: completion, index: nextIndex)
        }
    }
}
