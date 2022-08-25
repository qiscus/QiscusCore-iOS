// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "QiscusCore",
     platforms: [
            .macOS(.v10_12),
            .iOS(.v10),
    ],
    products: [
        .library(
            name: "QiscusCore",
            targets: ["QiscusCore"]),
    ],
    dependencies: [
       .package(url: "https://github.com/qiscus/QiscusRealtime-iOS.git", .upToNextMajor(from: "1.5.0-beta.2")),
 	.package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "QiscusCore",
            dependencies: [
	    .product(name: "QiscusRealtime", package: "QiscusRealtime-iOS"),
	    .product(name: "SwiftyJSON", package: "SwiftyJSON")],
	    path: "Source",  resources: [
            .process("Resources"),
            .process("Assets.xcassets"),
            .process("Qiscus.xcdatamodeld"),
        ]),
    ]
)