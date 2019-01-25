# ![Cauli](https://cauli.works/logo.png)

[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Cauli.svg?style=flat-square)](https://cocoapods.org/pods/Cauli)
[![License MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://github.com/cauliframework/cauli/blob/develop/LICENSE)

Cauli is a network debugging framework featuring a plugin infrastructure to hook into selected request and responses as well as recording and displaying performed requests.

## Features

* Hook into the URLLoadingSystem via plugins (we call them Florets)
* Easily use one of our [existing Florets](link_to_florets) to manipulate your network traffic or
* [Write your own Floret](https://cauli.works/docs/writing-your-own-plugin.html) to modify requests or responses accordingly to your needs
* Use our human readable file format to share your network traffic

## Example of usage

* Use the [InspectorFloret](https://cauli.works/docs/florets.html#InspectorFloret) to browse through your network traffic
* Suppress the network cache with the [NoCacheFloret](https://cauli.works/docs/florets.html#NoCacheFloret)
* Mock your UnitTests with the [MockFloret](https://cauli.works/docs/florets.html#MockFloret)
* Switch between live and staging backends by rewriting your request URLs with out [FindReplaceFloret](https://cauli.works/docs/florets.html#FindReplaceFloret)

## Getting Started

### Installation
#### [CocoaPods](https://cocoapods.org)

Use the following in your Podfile.

```ruby
pod 'Cauli', '~> 1.0'
```

Then run `pod install`.

#### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a non intrusive way to install Cauli to your project. It makes no changes to your Xcode project and workspace. Add the following to your Cartfile:

```swift
github "cauliframework/cauli"
```

### Setup

Add an `import Cauli` to your `AppDelegate` and call the `run` function on the shared instace in the `application(:, didFinishLaunchingWithOptions:)`.

```swift
import Cauli

public class AppDelegate: UIApplicationDelegate {
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Cauli.shared.run()
        // perform your usual application setup
        return true
    }
}
```

This will configure Cauli to hook into every request, setup the core florets (plugins) ([InspectorFloret](https://cauli.works/docs/Classes/InspectorFloret.html)) and configures a shake gesture for the Cauli UI.

### Documentation

* [Architecture](https://cauli.works/docs/architecture.html)
* [Configuring Cauli](https://cauli.works/docs/configuring-cauli.html)
* [Florets](https://cauli.works/docs/florets.html)
* [Writing Your Own Plugin](https://cauli.works/docs/writing-your-own-plugin.html)
* [Frequently Asked Questions](https://cauli.works/docs/frequently-asked-questions.html)

## Contributing
Please read [CONTRIBUTING](CONTRIBUTING.md) for details.

## License
Cauli is available under the [MIT license](LICENSE).
