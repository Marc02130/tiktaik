// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TIKtAIk",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "TIKtAIk",
            targets: ["TIKtAIk"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.20.0")
    ],
    targets: [
        .target(
            name: "TIKtAIk",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestoreSwift", package: "firebase-ios-sdk")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "TIKtAIkTests",
            dependencies: ["TIKtAIk"]),
    ]
) 