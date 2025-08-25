// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Lattice",
    platforms: [
        .macOS(.v15),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "Lattice",
            targets: ["Lattice"]),
        .executable(
            name: "LatticeDemo",
            targets: ["LatticeDemo"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto.git", "1.0.0" ..< "4.0.0"),
        .package(url: "https://github.com/pumperknickle/cashew.git", from: "0.0.3"),
        .package(url: "https://github.com/hyugit/UInt256.git", branch: "master")
    ],
    targets: [
        .target(
            name: "Lattice",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "cashew", package: "cashew"),
                .product(name: "UInt256", package: "UInt256")
            ]),
        .executableTarget(
            name: "LatticeDemo",
            dependencies: ["Lattice"]),
        .testTarget(
            name: "LatticeTests",
            dependencies: ["Lattice"])
    ]
)
