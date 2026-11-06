// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "swift-coach-marks",
	platforms: [.iOS(.v17)],
	products: [
		.library(name: "swift-coach-marks", targets: ["CoachMarks"]),
	],
	targets: [
		.target(
			name: "swift_coach_marks",
			swiftSettings: [
				.enableUpcomingFeature("ApproachableConcurrency"),
			],
		),
	]
)
