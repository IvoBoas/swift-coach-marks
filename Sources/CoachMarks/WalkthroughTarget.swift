import Foundation

public struct WalkthroughTarget: Identifiable, Equatable {
	public let id: String
	public let title: String
	public let description: String
	public let action: String

	public init(
		id: String,
		title: String,
		description: String,
		action: String
	) {
		self.id = id
		self.title = title
		self.description = description
		self.action = action
	}
}
