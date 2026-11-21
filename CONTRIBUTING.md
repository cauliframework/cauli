# Contributing

## 👋 How to lend a helping hand?

You like Cauli and want to help? You are the best! We welcome every kind of support and want to create a open community here.
You want to help but are unsure what? No worries! Here is an incomplete list of things you can support us with.

* Got an idea? Just **write an issue** and we can start a discussion.
* You already know some Cauli? Maybe there are **issues with questions you can help** with.
* Love **Unit tests**? We got some, but we bet you can improve them.
* Found a piece of bad **documentation**? Most of the initial documentation is written by non native speakers. Maybe you can improve on it.
* Want to roll up your sleeves and hack some code? Maybe you have a great idea for a feature you can add.


## 💻 How to contribute code changes?

Want to fix a bug, add a feature or improved one? What next? Here is a short guideline on how to get your changes merged.

* Go ahead and create a **fork** of Cauli
* **Branch off** the development branch
* **Commit** your changes
* Create a **Pull Request** to the development branch

Somebody will add two eyes to your code and might give some feedback. Got some changes merged? Welcome to the team! Let's try to make debugging better with Cauli!


## 🤔 How to get started?

Checked out the repository and would like some guidance to find your way?

* Cauli is a Swift package. Just open the `Package.swift` in Xcode. Here you can find all the code that make up Cauli.
* The unit tests use plain XCTest and don't need any third party dependencies. Run them with `⌘U` in Xcode, or from the command line:
  ```sh
  xcodebuild test -scheme Cauliframework -destination 'platform=iOS Simulator,name=iPhone 16'
  ```
* Have you seen the `Example` folder? In there we added an iOS example application. Open the `cauli-ios-example.xcodeproj` and have a look. You can use the example app to play around, test your changes or sketch out a new idea for a Floret.
* Please add an entry to the `CHANGELOG.md` for every change that affects the framework.
* The documentation is generated with [jazzy](https://github.com/realm/jazzy): `bundle install && bundle exec jazzy`. Ruby is only needed for this.
* The documentation on [cauli.works/docs](https://cauli.works/docs) is generated and published by the "Documentation" workflow whenever a release is tagged. It can also be run manually to check the generated documentation.
* CocoaPods is only used for distribution. The `Cauliframework.podspec` is linted on CI, but there is no need to install CocoaPods for development.
