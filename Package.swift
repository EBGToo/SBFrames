// swift-tools-version:5.5
//
//  Package.swift
//  SBFrames
//
//  Created by Ed Gamble on 12/3/15.
//  Copyright © 2015 Edward B. Gamble Jr.  All rights reserved.
//
//  See the LICENSE file at the project root for license information.
//  See the CONTRIBUTORS file at the project root for a list of contributors.
//

import PackageDescription

let package = Package(
    name: "SBFrames",
    platforms: [
        .macOS("11.1")
    ],

    products: [
        .library(
            name: "SBFrames",
            targets: ["SBFrames"]),
    ],

    dependencies: [
        .package(url: "https://github.com/EBGToo/SBUnits", .upToNextMajor(from: "0.1.0"))

    ],

    targets: [
        .target(
            name: "SBFrames",
            dependencies: ["SBUnits"],
            path: "Sources"
        ),
        .testTarget(
            name: "SBFramesTests",
            dependencies: ["SBFrames"],
            path: "Tests"
        ),
    ]
)
