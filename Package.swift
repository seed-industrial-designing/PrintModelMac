// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "PrintModel",
	defaultLocalization: "en",
	platforms: [.macOS(.v10_15), .iOS(.v15)],
	products: [
		.library(
			name: "PrintModel",
			targets: ["PrintModel"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/seed-industrial-designing/PipeModelMac.git", from: "1.0.0"),
	],
	targets: [
		.target(
			name: "PrintModel",
			dependencies: [
				.product(name: "PipeModel", package: "PipeModelMac"),
			],
			path: "Sources",
			resources: [
				.process("Resources")
			]
		),
		.testTarget(
			name: "PrintModelTests",
			dependencies: [
				.target(name: "PrintModel")
			]
		),
	]
)
