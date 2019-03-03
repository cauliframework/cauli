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

import UIKit

internal class ViewControllerShakePresenter {

    private var viewController: (() -> (UIViewController?))

    /// This initializes a `ViewControllerShakePresenter` which will, when the device is shaked,
    /// modally present a `UINavigationController`. The passed ViewController will be the
    /// `rootViewController` of the `UINavigationController`.
    ///
    /// - Parameter viewController: A viewController that will be the `rootViewController` of a UINavigationController.
    init(_ viewController: @escaping () -> (UIViewController?)) {
        self.viewController = viewController
        self.shakeMotionDidEndObserver = NotificationCenter.default.addObserver(forName: Notification.shakeMotionDidEnd, object: nil, queue: nil) { [weak self] _ in
            self?.toggleViewController()
        }
    }

    private var shakeMotionDidEndObserver: NSObjectProtocol?

    private func presentingViewController() -> UIViewController? {
        var presentingViewController = UIApplication.shared.keyWindow?.rootViewController
        while let presentedViewController = presentingViewController?.presentedViewController {
            presentingViewController = presentedViewController
        }
        return presentingViewController
    }

    weak var presentedViewController: UIViewController?
    private func toggleViewController() {
        let presentingViewController = self.presentingViewController()
        if let presentedViewController = presentedViewController,
            presentedViewController.presentingViewController != nil {
            presentedViewController.dismiss(animated: true, completion: nil)
        } else if let viewController = self.viewController() {
            let navigationController = UINavigationController(rootViewController: viewController)
            let doneBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissPresentedViewController))
            viewController.navigationItem.rightBarButtonItem = doneBarButtonItem
            presentedViewController = navigationController
            presentingViewController?.present(navigationController, animated: true, completion: nil)
        }
    }

    @objc private func dismissPresentedViewController() {
        presentedViewController?.dismiss(animated: true, completion: nil)
    }
}
