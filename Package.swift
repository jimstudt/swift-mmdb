// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MMDB",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "MMDB",
            targets: ["MMDB"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "MMDB",
            dependencies: []),
        .testTarget(
            name: "MMDBTests",
            dependencies: ["MMDB"],
            exclude: ["MaxMind-DB/source-data",
                      "MaxMind-DB/MaxMind-DB-spec.md",
                      "MaxMind-DB/LICENSE",
                      "MaxMind-DB/perltidyrc",
                      "MaxMind-DB/tidyall.ini",
                      "MaxMind-DB/README.md"],
            resources: [ .copy("MaxMind-DB/test-data"), .copy("MaxMind-DB/bad-data") ] ),
    ]
)
