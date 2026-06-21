// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WSDL2SwiftPM",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "WSDL2SwiftPM",
            targets: ["WSDL2SwiftPM"]),
        .library(
            name: "Toki",
            targets: ["Toki"]),
        .executable(
            name: "WSDL2SwiftPMCLI",
            targets: ["WSDL2SwiftPMCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tadija/AEXML.git", exact: "4.7.0"),
        .package(url: "https://github.com/Thomvis/BrightFutures.git", exact: "8.2.0"),
        .package(url: "https://github.com/cezheng/Fuzi.git", exact: "3.1.3"),

        .package(url: "https://github.com/kylef/Commander.git", exact: "0.9.2"),
        .package(url: "https://github.com/stencilproject/Stencil.git", exact: "0.15.1"),
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs.git", exact: "9.1.0"),
    ],
    targets: [
        .target(
            name: "WSDL2SwiftPM",
            dependencies: [
                "AEXML",
                "BrightFutures",
                "Fuzi",
            ],
            path: "Sources/WSDL2SwiftPM",
        ),
        .target(
            name: "Toki",
            dependencies: [
                "WSDL2SwiftPM",
                "AEXML",
                "Fuzi",
                "OHHTTPStubs",
            ],
            path: "Sources/Toki",
        ),
        .executableTarget(
            name: "WSDL2SwiftPMCLI",
            dependencies: [
                "WSDL2SwiftPM",
                "Commander",
                "Stencil",
            ],
            path: "Sources/WSDL2SwiftPMCLI",
            resources: [
                .copy("Stencils")
            ],
        ),
        .testTarget(
            name: "WSDL2SwiftPMTests",
            dependencies: [
                "WSDL2SwiftPM"
            ],
            path: "Tests/WSDL2SwiftPMTests",
        ),
        .testTarget(
            name: "TokiTests",
            dependencies: [
                "WSDL2SwiftPM",
                "Toki",
                "OHHTTPStubs",
            ],
            path: "Tests/TokiTests",
        ),
    ],
)
