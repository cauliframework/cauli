// swift-tools-version:5.3
//
// Cauliframework
//

import PackageDescription

let package = Package(
    name: "Cauliframework",
    platforms: [
        .iOS(.v11),
    ],
    products: [
        .library(
            name: "Cauliframework",
            targets: ["Cauliframework"]
        )
    ],
    targets: [
        .target(
            name: "Cauliframework",
            dependencies: [],
            path: "Cauli",
            resources: [
              .process("Resources/*")
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)
