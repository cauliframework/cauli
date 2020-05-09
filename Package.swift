// swift-tools-version:5.0
//
// Cauliframework
//

import PackageDescription

let package = Package(
    name: "Cauliframework",
    platforms: [
        .iOS(.v8),
    ],
    products: [
        .library(name: "Cauliframework", targets: ["Cauliframework"])
    ],
    targets: [
        .target(name: "Cauliframework", dependencies: [], path: "Cauli"),
    ],
   swiftLanguageVersions:[.v5]
)
