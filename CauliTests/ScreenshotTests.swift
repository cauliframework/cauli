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

/// Temporary: renders the screens of the SecurityAuditFloret into `SCREENSHOT_DIR`.
final class ScreenshotTests: XCTestCase {

    func testTakeScreenshots() throws {
        guard let directory = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] else {
            throw XCTSkip("SCREENSHOT_DIR is not set")
        }
        let suiteName = "ScreenshotTests.\(UUID().uuidString)"
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let floret = SecurityAuditFloret(firstPartyHosts: ["example.com"], userDefaults: userDefaults)
        fill(floret)
        let cauli = Cauli([InspectorFloret(), floret, NoCacheFloret()], configuration: Configuration(recordSelector: .all(), enableShakeGesture: false, storageCapacity: .records(1)))
        cauli.run()
        defer { cauli.pause() }

        let device = UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        let secrets = try XCTUnwrap(floret.issues.first { $0.title == "Secrets in URLs" })
        let screens: [(String, () -> UIViewController)] = [
            ("1-menu", { CauliViewController(cauli: cauli) }),
            ("2-findings", { SecurityAuditViewController(floret: floret) }),
            ("3-finding", { SecurityAuditIssueViewController(floret: floret, issue: secrets) }),
            ("4-ignored", { SecurityAuditIgnoredViewController(floret: floret) })
        ]
        for (name, makeViewController) in screens {
            for style in [UIUserInterfaceStyle.light, .dark] {
                let image = render(makeViewController(), style: style)
                let file = URL(fileURLWithPath: directory).appendingPathComponent("\(device)-\(name)-\(style == .dark ? "dark" : "light").png")
                try XCTUnwrap(image.pngData()).write(to: file)
            }
        }
    }

    private func fill(_ floret: SecurityAuditFloret) {
        let exchanges = [
            SecurityAuditFixture.exchange("http://staging.example.com/me", headers: ["Authorization": "Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI0MiJ9"]),
            SecurityAuditFixture.exchange("https://api.example.com/users/jane.doe%40example.com", responseHeaders: ["Strict-Transport-Security": "max-age=31536000"]),
            SecurityAuditFixture.exchange("https://analytics.example.net/track?email=jane.doe@example.com&event=open", responseHeaders: ["Strict-Transport-Security": "max-age=31536000"]),
            SecurityAuditFixture.exchange("https://api.example.com/login", responseHeaders: ["Strict-Transport-Security": "max-age=31536000", "Set-Cookie": "session=4f9a1c2e8b7d; Path=/; Secure; SameSite=Lax"]),
            SecurityAuditFixture.exchange("https://images.example-cdn.com/hero.jpg", responseHeaders: [:]),
            SecurityAuditFixture.exchange("https://auth.example.com/.well-known/openid-configuration", responseHeaders: [:]),
            SecurityAuditFixture.exchange("http://192.168.1.20:8080/api/7")
        ]
        exchanges.forEach { floret.audit($0) }
        for page in 0..<38 {
            floret.audit(SecurityAuditFixture.exchange("https://api.example.com/feed?page=\(page)&access_token=eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI0MiJ9.dBjftJeZ4CVP", responseHeaders: ["Strict-Transport-Security": "max-age=31536000"]))
        }
        for query in 0..<22 {
            floret.audit(SecurityAuditFixture.exchange("https://api.example.com/search?q=\(query)&access_token=eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI0MiJ9.dBjftJeZ4CVP", responseHeaders: ["Strict-Transport-Security": "max-age=31536000"]))
        }
        if let cleartext = floret.issues.first(where: { $0.title == "Cleartext HTTP" && $0.endpoints.contains { $0.name.contains("192.168") } }) {
            floret.ignore(SecurityAuditIssue(identifier: cleartext.identifier, severity: cleartext.severity, endpoints: cleartext.endpoints.filter { $0.name.contains("192.168") }, example: cleartext.example))
        }
    }

    private func render(_ viewController: UIViewController, style: UIUserInterfaceStyle) -> UIImage {
        let window: UIWindow
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            window = UIWindow(windowScene: scene)
            window.frame = scene.coordinateSpace.bounds
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
