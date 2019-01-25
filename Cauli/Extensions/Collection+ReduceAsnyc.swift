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

internal extension Collection {

    typealias AsynchTransformation<Product> = (Product, Element, @escaping (Product) -> Void) -> Void

    func cauli_reduceAsync<Product>(_ initial: Product, transform: @escaping AsynchTransformation<Product>, completion: @escaping (Product) -> Void) {
        cauli_reduceAsync(initial, transform: transform, completion: completion, index: startIndex)
    }

    fileprivate func cauli_reduceAsync<Product>(_ initial: Product, transform: @escaping AsynchTransformation<Product>, completion: @escaping (Product) -> Void, index: Index) {
        guard index < endIndex else { return completion(initial) }
        let element = self[index]
        transform(initial, element) { result in
            let nextIndex = self.index(after: index)
            self.cauli_reduceAsync(result, transform: transform, completion: completion, index: nextIndex)
        }
    }
}
