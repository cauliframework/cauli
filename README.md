# ![Cauli](https://cauli.works/logo.png)

[![Tests](https://github.com/cauliframework/cauli/workflows/Tests/badge.svg)](https://github.com/cauliframework/cauli/actions)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Cauliframework.svg?style=flat-square)](https://cocoapods.org/pods/Cauliframework)
[![License MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://github.com/cauliframework/cauli/blob/develop/LICENSE)
[![Jazzy documentation](https://cauli.works/docs/badge.svg)](https://cauli.works/docs/)

Cauli is a network debugging framework featuring a plugin infrastructure to hook into selected request and responses as well as recording and displaying performed requests. It provides a wide range of possibilities. For example from [inspecting](https://cauli.works/docs/florets.html#InspectorFloret) network traffic to [mock](https://cauli.works/docs/florets.html#MockFloret) UnitTests. Missing something fancy? How about [writing your own Plugin](https://cauli.works/docs/writing-your-own-plugin.html).

## Features

🌏 Hooks into the [URL Loading System](https://cauli.works/docs/frequently-asked-questions.html)  
🧩 [Existing](https://cauli.works/docs/florets.html) set of Plugins (Florets)  
🔧 [Extensible](https://cauli.works/docs/writing-your-own-plugin.html) Plugin Infrastructure

### Documentation

* [Architecture](https://cauli.works/docs/architecture.html)
* [Configuring Cauli](https://cauli.works/docs/configuring-cauli.html)
* [Plugins / Florets](https://cauli.works/docs/florets.html)
* [Writing Your Own Plugin / Floret](https://cauli.works/docs/writing-your-own-plugin.html)
* [Frequently Asked Questions](https://cauli.works/docs/frequently-asked-questions.html)

## Getting Started

### Installation

```

#### [Swift Package Manager](https://swift.org/package-manager/)

The Swift Package Manager is a tool for automating the distribution of Swift code and is integrated into the swift compiler. Once you have your Swift package set up, add the following to your `Package.swift` file.

```swift
dependencies: [
    .package(url: "https://github.com/cauliframework/cauli.git", from: "1.0.1")
]
```

### Setup

Add an `import Cauliframework` to your `AppDelegate` and call the `run` function on the shared instace in the `application(:, didFinishLaunchingWithOptions:)`. Make sure to call `run` before instantiating any `URLSession`. Otherwise Cauli can't intercept network requests and create any records.

```swift
import Cauliframework

public class AppDelegate: UIApplicationDelegate {
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Cauli.shared.run()
        // perform your usual application setup
        return true
    }
}
```

This will configure Cauli to hook into every request, setup the core florets (plugins) ([InspectorFloret](https://cauli.works/docs/Classes/InspectorFloret.html)) and configures a shake gesture for the Cauli UI.

## Contributing
Please read [CONTRIBUTING](CONTRIBUTING.md) for details.

## License
Cauli is available under the [MIT license](LICENSE).
