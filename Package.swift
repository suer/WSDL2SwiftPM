// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WSDL2Swift",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "WSDL2Swift",
            targets: ["WSDL2Swift"]),
        .executable(
            name: "WSDL2SwiftCLI",
            targets: ["WSDL2SwiftCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tadija/AEXML.git", exact: "4.7.0"),
        .package(url: "https://github.com/Thomvis/BrightFutures.git", exact: "8.2.0"),
        .package(url: "https://github.com/cezheng/Fuzi.git", exact: "3.1.3"),

        .package(url: "https://github.com/kylef/Commander.git", exact: "0.9.2"),
        .package(url: "https://github.com/stencilproject/Stencil.git", exact: "0.15.1"),
    ],
    targets: [
        .target(
            name: "WSDL2Swift",
            dependencies: [
                "AEXML",
                "BrightFutures",
                "Fuzi",
            ],
            path: ".",
            exclude: [
                "WSDL2Swift",
                "LICENSE",
                "README.md",
            ],
            sources: ["WSDL2Swift.swift"],
        ),
        .executableTarget(
            name: "WSDL2SwiftCLI",
            dependencies: [
                "WSDL2Swift",
                "Commander",
                "Stencil",
            ],
            path: "WSDL2Swift",
            resources: [
                .copy("Stencils")
            ],
        ),
    ],
)
