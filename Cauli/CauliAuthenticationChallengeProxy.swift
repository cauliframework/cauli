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

/// The CauliAuthenticationChallengeProxy works as a proxy between URLAuthenticationChallengeSender and the `urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)` completionHandler.
internal class CauliAuthenticationChallengeProxy: NSObject, URLAuthenticationChallengeSender {

    private let authChallengeCompletionHandler: ((URLSession.AuthChallengeDisposition, URLCredential?) -> Void)

    init(authChallengeCompletionHandler: @escaping ((URLSession.AuthChallengeDisposition, URLCredential?) -> Void)) {
        self.authChallengeCompletionHandler = authChallengeCompletionHandler
    }

    func performDefaultHandling(for challenge: URLAuthenticationChallenge) {
        authChallengeCompletionHandler(.performDefaultHandling, nil)
    }

    func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {
        authChallengeCompletionHandler(.useCredential, credential)
    }

    func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {
        authChallengeCompletionHandler(.performDefaultHandling, nil)
    }

    func cancel(_ challenge: URLAuthenticationChallenge) {
        authChallengeCompletionHandler(.cancelAuthenticationChallenge, nil)
    }
}
