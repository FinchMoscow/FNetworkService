// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    
    name: "FNetworkService",
   
    platforms: [
        .iOS(.v10),
    ],
   
    products: [
        .library(
            name: "FNetworkService",
            targets: ["FNetworkService"]),
    ],
    
    dependencies: [
    .package(url: "https://github.com/Alamofire/Alamofire.git",
             from: "4.8.2")
    ],
    
    targets: [
        .target(
            name: "FNetworkService",
            dependencies: [
                .byName(name: "Alamofire")
        ])
    ]
)

