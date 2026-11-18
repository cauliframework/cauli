// swift-tools-version:5.9
//
// Cauliframework
//

import PackageDescription

let package = Package(
    name: "Cauliframework",
    platforms: [
        .iOS(.v13),
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
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "CauliframeworkTests",
            dependencies: ["Cauliframework"],
            path: "CauliTests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
