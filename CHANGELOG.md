# Changelog

## Unreleased
* **bugfix** Fixed timed out and cancelled requests not getting a result in the `InspectorFloret` and the other florets. They are now recorded with the error the app receives, e.g. a timeout instead of a cancellation. [#160](https://github.com/cauliframework/cauli/issues/160)
* **bugfix** Fixed switching off an `InterceptingFloret` implemented as a struct in the Cauli menu having no effect. [#255](https://github.com/cauliframework/cauli/issues/255)
* **bugfix** Fixed data races when florets are switched on or off, or Cauli is paused or resumed, while requests are running. [#255](https://github.com/cauliframework/cauli/issues/255)
* **improvement** Added dark mode support. The plaintext viewer of the `InspectorFloret` and the floret list of the Cauli menu don't show white backgrounds in dark mode anymore.
* **improvement** Removed the CocoaPods and Carthage support. Cauli is only distributed via the Swift Package Manager. Version 1.2 remains available on CocoaPods.

## 1.2
* **improvement** The record details of the `InspectorFloret` now show the beginning of text bodies next to their size, with JSON compacted to show as much of it as possible. [#153](https://github.com/cauliframework/cauli/issues/153)
* **improvement** Added a guide describing how the `MockFloret` records and mocks requests, and the format of its mocks. [#166](https://github.com/cauliframework/cauli/issues/166)
* **feature** Added a `mockFolder` parameter to the `MockFloret`, to read mocks from another folder in the bundle or, in the simulator, from a folder on your Mac. [#226](https://github.com/cauliframework/cauli/issues/226), [#100](https://github.com/cauliframework/cauli/issues/100)
* **improvement** Documented that the upload progress isn't reported for intercepted requests, and how to exclude uploads from Cauli. [#202](https://github.com/cauliframework/cauli/issues/202)
* **feature** Added `Cauli.isRunning` to check whether a Cauli instance currently intercepts requests. [#188](https://github.com/cauliframework/cauli/issues/188)
* **feature** Added a cURL command to the request details of the `InspectorFloret`, which can be viewed, copied and shared. Based on [#222](https://github.com/cauliframework/cauli/pull/222) by @pstued
* **bugfix** Fixed the `MapRemoteFloret`'s mappings not being reachable from the Cauli menu. It is now listed as displaying floret as well.
* **bugfix** Fixed responses being delivered with duplicated data, or data before the response, once a record stops being handled while it loads, e.g. a chunked response growing beyond the `RecordSelector.max(bytesize:)` limit.
* **bugfix** Fixed a stopped request still being started, or reported to the client, when the florets finished modifying it afterwards.
* **bugfix** Fixed a deadlock when the main thread waits for a request that Cauli intercepts.
* **bugfix** Fixed the `HTTPBodyStreamFloret` sending requests without their body if it exceeds the `maximumConvertedByteSize`, and crashing when the body stream fails.
* **bugfix** Fixed a crash on iPad when sharing a record or selecting a record detail in the `InspectorFloret`.
* **improvement** Raised the minimum deployment target to iOS 13.
* **improvement** Migrated the unit tests from Quick, Nimble and OHHTTPStubs to XCTest. The tests are now part of the `Package.swift`, the Xcode project and workspace have been removed.
* **improvement** Removed Danger and the remaining CocoaPods development setup. CocoaPods is only used for distribution.
* **improvement** Updated the CI to current macOS runners and Xcode versions and added SwiftLint and podspec linting.
* **bugfix** Fixed the `MapRemoteFloret` list not loading its cell when using Cauli via SPM.
* **bugfix** Fixed an issue where the inspector wouldn’t use the formatters filter. [#246](https://github.com/cauliframework/cauli/pull/246)

## 1.1
* **feature** Added a `MapRemoteFloret` that can change urls of requests before they are sent. [#216](https://github.com/cauliframework/cauli/issues/216) by @brototyp
* **improvement** Added an optional description to florets [#176](https://github.com/cauliframework/cauli/issues/176) by @Shukuyen  
* **improvement** Removed Cocoapods as a developer dependency in favor of SPM. [#238](https://github.com/cauliframework/cauli/pull/238)
* **improvement** Extracted the `InspectorFloretFormatter` to increase customizability if the `InspectorFloret`. [#239](https://github.com/cauliframework/cauli/pull/239)
* **bugfix** Fixed an issue where cauli didn’t pass the redirection information up to the application. [#196](https://github.com/cauliframework/cauli/issues/196)
* **bugfix** Fixed an issue when using Cauli via SPM. [#238](https://github.com/cauliframework/cauli/pull/238)

## 1.0.1
* **improvement** Added Support for iOS 8 and 9. [#164](https://github.com/cauliframework/cauli/issues/164) by @brototyp
* **improvement** Redesigned Inspector Floret record list. [#179](https://github.com/cauliframework/cauli/issues/179) by @Shukuyen
* **bugfix** Fixed a bug where a Cauli instance did not consider the enabled state when deciding whether to handle a record or not. [#185](https://github.com/cauliframework/cauli/issues/185) by @pstued

## 1.0
* **feature** Added a `HTTPBodyStreamFloret` to improve the compatibilty to requests with `httpBodyStream`s. [#154](https://github.com/cauliframework/cauli/pull/154) by @brototyp
* **improvement** Changed the name of the framework from `Cauli` to `Cauliframework`. [#135](https://github.com/cauliframework/cauli/issues/135)
* **improvement** Changed the `max` and `all` functions on `RecordSelector` to be public. [#136](https://github.com/cauliframework/cauli/issues/136)
* **improvement** Added a search to the Inspector Floret that allows filtering the record list by URL. [#134](https://github.com/cauliframework/cauli/pull/134) by @shukuyen
* **improvement** Added some description to the `CauliViewController`s sections. [#157](https://github.com/cauliframework/cauli/issues/157) by @pstued
* **improvement** Added `preStorageRecordModifier` to `Configuration` and `Storage` to allow for records to be modified before they are stored. [#146](https://github.com/cauliframework/cauli/pull/146) by @shukuyen
* **improvement** Added a done button to dismiss the CauliViewController when the ViewController is displayed via the shake gesture. [#114](https://github.com/cauliframework/cauli/issues/114) by @pstued
* **improvement** Added a PlaintextPrettyPrinter and manual selection [#91](https://github.com/cauliframework/cauli/issues/91) by @brototyp  
* **improvement** Splitted the Floret protocol into InterceptingFloret and DisplayingFloret protocols for a better separation of a Florets functionality and responsibility. [#155](https://github.com/cauliframework/cauli/issues/155) by @pstued
* **bugfix** Fixed an issue where records cells were cropped in the InspectorViewController. [#147](https://github.com/cauliframework/cauli/issues/147)
* **bugfix** Fixed a bug where Records would be duplicated in the InspectorViewController. [#148](https://github.com/cauliframework/cauli/issues/148) by @brototyp
* **bugfix** Fixed a bug where the searchbar could cover the first entry in the InspectorViewController. [#144](https://github.com/cauliframework/cauli/issues/144) by @brototyp
* **bugfix** Fixed a bug where searching in the InspectorFloret would not load additional records [#161](https://github.com/cauliframework/cauli/pull/161) by @shukuyen

## 0.9
* First public release
