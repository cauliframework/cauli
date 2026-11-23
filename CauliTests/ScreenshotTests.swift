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

@testable import Cauliframework
import UIKit
import XCTest

/// Temporary: renders the screens of the NetworkUsageFloret into `SCREENSHOT_DIR`.
final class ScreenshotTests: XCTestCase {

    func testTakeScreenshots() throws {
        guard let directory = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] else {
            throw XCTSkip("SCREENSHOT_DIR is not set")
        }
        let device = UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        let floret = NetworkUsageFloret()
        fill(floret)
        let usage = floret.snapshot
        let hints = floret.hints(for: usage)
        let screens: [(String, CGFloat, () -> UIViewController)] = [
            ("1-overview", 1_700, { NetworkUsageViewController(floret: floret) }),
            ("2-hint", 0, { NetworkUsageHintViewController(hint: hints[0]) }),
            ("3-host", 0, { NetworkUsageHostViewController(host: usage.hosts[0], usage: usage, hints: hints) })
        ]
        for (name, height, makeViewController) in screens {
            for style in [UIUserInterfaceStyle.light, .dark] {
                let image = render(makeViewController(), style: style, height: height)
                let file = URL(fileURLWithPath: directory).appendingPathComponent("\(device)-\(name)-\(style == .dark ? "dark" : "light").png")
                try XCTUnwrap(image.pngData()).write(to: file)
            }
        }
    }

    private func fill(_ floret: NetworkUsageFloret) {
        let api = "https://api.example.com"
        for page in 0..<38 {
            respond(floret, "\(api)/feed?page=\(page)", headers: ["Content-Type": "application/json", "Content-Encoding": "gzip", "Cache-Control": "max-age=60"], body: 18_000, decoded: 76_000)
        }
        for user in 0..<61 {
            respond(floret, "\(api)/users/\(user % 20)", headers: ["Content-Type": "application/json", "ETag": "\"1\""], body: 10_000)
        }
        for query in 0..<22 {
            respond(floret, "\(api)/search?q=\(query)", headers: ["Content-Type": "application/json", "ETag": "\"1\""], body: 18_600)
        }
        for _ in 0..<14 {
            respond(floret, "\(api)/config", headers: ["Content-Type": "application/json", "Content-Encoding": "br"], body: 5_000, decoded: 22_000)
        }
        for _ in 0..<18 {
            respond(floret, "\(api)/events", method: "POST", headers: ["Content-Type": "application/json"], body: 400, requestBody: 16_000)
        }
        let cdn = "https://images.example-cdn.com"
        for image in 0..<53 {
            respond(floret, "\(cdn)/thumbnails/\(image).jpg", headers: ["Content-Type": "image/jpeg", "Cache-Control": "max-age=86400"], body: 11_000, fromCache: image < 31, protocolName: "h3")
        }
        respond(floret, "\(cdn)/images/hero.jpg", headers: ["Content-Type": "image/jpeg", "Cache-Control": "max-age=86400"], body: 820_000, protocolName: "h3")
        for event in 0..<32 {
            respond(floret, "https://analytics.example.net/track", method: "POST", headers: ["Content-Type": "text/plain"], body: 9_000, requestBody: 600, protocolName: "http/1.1", reused: event % 4 == 0)
        }
    }

    // swiftlint:disable:next function_parameter_count
    private func respond(_ floret: NetworkUsageFloret, _ url: String, method: String = "GET", headers: [String: String], body: Int64, decoded: Int64? = nil, requestBody: Int64 = 0, fromCache: Bool = false, protocolName: String = "h2", reused: Bool = true) {
        let requestURL = URL(string: url)!
        var request = URLRequest(url: requestURL)
        request.httpMethod = method
        var record = Record(request)
        let response = HTTPURLResponse(url: requestURL, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)!
        record.result = .result(Response(response, data: nil))
        record.metrics = TransferMetrics(requestHeaderBytes: 320, requestBodyBytes: requestBody, responseHeaderBytes: 380, responseBodyBytes: body, responseBodyBytesDecoded: decoded ?? body, isFromCache: fromCache, networkProtocol: protocolName, isReusedConnection: reused, duration: Double((url.count * 37) % 400) / 1_000 + 0.05)
        floret.didRespond(record) { _ in }
    }

    private func render(_ viewController: UIViewController, style: UIUserInterfaceStyle, height: CGFloat) -> UIImage {
        let window: UIWindow
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            window = UIWindow(windowScene: scene)
            window.frame = scene.coordinateSpace.bounds
            if height > 0 {
                window.frame.size.height = height
            }
        } else {
            window = UIWindow(frame: UIScreen.main.bounds)
        }
        window.overrideUserInterfaceStyle = style
        window.rootViewController = UINavigationController(rootViewController: viewController)
        window.makeKeyAndVisible()
        RunLoop.main.run(until: Date().addingTimeInterval(1))
        window.layoutIfNeeded()
        // The test host doesn't draw the window on screen, so render the layers directly.
        let format = UIGraphicsImageRendererFormat(for: window.traitCollection)
        format.opaque = true
        let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { context in
            window.traitCollection.performAsCurrent {
                UIColor.systemBackground.setFill()
                context.fill(window.bounds)
                window.layer.render(in: context.cgContext)
            }
        }
        window.isHidden = true
        return image
    }

}
