# Changelog

## Unreleased
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

## 0.9
* First public release
