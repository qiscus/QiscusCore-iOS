// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "QiscusCore",
    products: [
        .library(
            name: "QiscusCore",
            targets: ["QiscusCore"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
       .package(url: "https://github.com/qiscus/QiscusRealtime-iOS.git", .upToNextMajor(from: "1.5.0-beta.1")),
 	.package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "QiscusCore",
            dependencies: ["QiscusRealtime"],
 	    dependencies: ["SwiftyJSON"],
	    path: "Source"),
    ]
)
