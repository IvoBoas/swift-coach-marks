import SwiftUI

struct WalkthroughAnchorKey: PreferenceKey {
	struct AnchorTarget {
		let target: WalkthroughTarget
		let shape: AnyShape
		let horizontalPadding: CGFloat
		let verticalPadding: CGFloat
		let bounds: Anchor<CGRect>
	}

	static var defaultValue: [AnchorTarget] { [] }

	static func reduce(
		value: inout [AnchorTarget],
		nextValue: () -> [AnchorTarget]
	) {
		value.append(contentsOf: nextValue())
	}
}
