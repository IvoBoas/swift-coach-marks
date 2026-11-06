import SwiftUI
import UIDefinition

public struct WalkthroughOverlay: View {
	let model: WalkthroughTarget
	let target: CGRect
	let shape: AnyShape
	let containerSize: CGSize
	let action: (WalkthroughInteraction) -> Void

	@State private var tooltipHeight: CGFloat = .zero

	public init(
		model: WalkthroughTarget,
		target: CGRect,
		shape: AnyShape,
		containerSize: CGSize,
		action: @escaping (WalkthroughInteraction) -> Void
	) {
		self.model = model
		self.target = target
		self.shape = shape
		self.containerSize = containerSize
		self.action = action
	}

	public var body: some View {
		let tooltipX: CGFloat = min(
			max(.tooltipTargetSpacing, target.midX - .tooltipWidth / 2),
			max(.tooltipTargetSpacing, containerSize.width - .tooltipWidth - .tooltipTargetSpacing)
		)

		let spaceBelow = containerSize.height - target.maxY
		let requiredSpace = tooltipHeight + .tooltipTargetSpacing * 2
		let showsBelow = spaceBelow >= requiredSpace || spaceBelow >= target.minY

		let tooltipY = showsBelow
			? target.maxY + .tooltipTargetSpacing
			: target.minY - .tooltipTargetSpacing - tooltipHeight

		ZStack(alignment: .topLeading) {
			Color.backgroundOverlay.ignoresSafeArea()
				.overlay {
					shape
						.frame(width: target.width, height: target.height)
						.position(x: target.midX, y: target.midY)
						.blendMode(.destinationOut)
				}
				.compositingGroup()
				.onTapGesture { action(.background) }

			Color.clear
				.frame(width: target.width, height: target.height)
				.contentShape(shape)
				.onTapGesture { action(.target) }
				.position(x: target.midX, y: target.midY)

			WalkthroughTooltip(
				target: model,
				arrowX: target.midX - tooltipX,
				arrowEdge: showsBelow ? .top : .bottom
			) {
				action(.actionButton)
			}
			.modifier(GeometryGroupIfAvailable())
			.onGeometryChange(for: CGFloat.self) { $0.size.height } action: { tooltipHeight = $0 }
			.offset(x: tooltipX, y: tooltipY)
		}
		.frame(width: containerSize.width, height: containerSize.height)
	}
}

// MARK: - Modifiers
public extension View {
	func walkthroughTarget(
		_ target: WalkthroughTarget,
		shape: some Shape = RoundedRectangle(cornerRadius: .radiusL),
		horizontalPadding: CGFloat = .zero,
		verticalPadding: CGFloat = .zero
	) -> some View {
		transformAnchorPreference(key: WalkthroughAnchorKey.self, value: .bounds) {
			$0.append(
				WalkthroughAnchorKey.AnchorTarget(
					target: target,
					shape: AnyShape(shape),
					horizontalPadding: horizontalPadding,
					verticalPadding: verticalPadding,
					bounds: $1
				)
			)
		}
	}

	func walkthroughContainer(
		target: WalkthroughTarget?,
		actionHandler: @escaping (WalkthroughTarget.ID, WalkthroughInteraction) -> Void
	) -> some View {
		overlayPreferenceValue(WalkthroughAnchorKey.self) { anchors in
			GeometryReader { proxy in
				if let target, let anchor = anchors.first(where: { $0.target.id == target.id }) {
					WalkthroughOverlay(
						model: target,
						target: proxy[anchor.bounds].insetBy(dx: -anchor.horizontalPadding, dy: -anchor.verticalPadding),
						shape: anchor.shape,
						containerSize: proxy.size
					) {
						actionHandler(target.id, $0)
					}
					.transition(.opacity)
				}
			}
		}
		.animation(.spring, value: target)
	}

	func singleWalkthroughContainer(
		target: Binding<WalkthroughTarget?>,
		onTargetTap: @escaping () -> Void = {}
	) -> some View {
		walkthroughContainer(target: target.wrappedValue) { _, interaction in
			target.wrappedValue = nil

			if interaction == .target {
				onTargetTap()
			}
		}
	}
}

private struct GeometryGroupIfAvailable: ViewModifier {
	func body(content: Content) -> some View {
		if #available(iOS 17, *) {
			content.geometryGroup()
		} else {
			content
		}
	}
}

// MARK: - Constants
private extension CGFloat {
	static let tooltipTargetSpacing: Self = .spacingM
}

private extension Color {
	static let backgroundOverlay: Self = Color(hex: 0x1F222C, opacity: 0.5)
}

// MARK: - Previews
#if DEBUG
@available(iOS 17, *) #Preview("Single Target") {
	@Previewable @State var target: WalkthroughTarget? = .forYou
	@Previewable @State var offset: CGSize = .zero
	@Previewable @State var lastOffset: CGSize = .zero

	ZStack {
		Color.primary500.ignoresSafeArea()

		Button { target = .forYou } label: {
			Capsule()
				.fill(.white)
				.frame(width: 96, height: 36)
		}
		.walkthroughTarget(.forYou, shape: .capsule)
		.offset(offset)
	}
	.singleWalkthroughContainer(target: $target)
	.gesture(
		DragGesture()
			.onChanged {
				offset = CGSize(
					width: lastOffset.width + $0.translation.width,
					height: lastOffset.height + $0.translation.height
				)
			}
			.onEnded { _ in lastOffset = offset }
	)
}

@available(iOS 17, *) #Preview("Walkthrough Flow") {
	@Previewable @State var target: WalkthroughTarget? = .flowForYou
	let steps: [WalkthroughTarget] = [.flowForYou, .flowProfile, .flowDailyPlan, .flowReset]

	ZStack {
		Color.primary500.ignoresSafeArea()

		VStack(spacing: .spacingL) {
			HStack {
				Capsule()
					.fill(.white)
					.frame(width: 96, height: 36)
					.walkthroughTarget(.flowForYou, shape: .capsule)

				Spacer()

				Circle()
					.fill(.white)
					.frame(width: 44, height: 44)
					.walkthroughTarget(.flowProfile, shape: .circle)
			}

			Spacer()

			RoundedRectangle(cornerRadius: .radiusL)
				.fill(.white)
				.frame(height: 120)
				.walkthroughTarget(.flowDailyPlan)

			Spacer()

			Button("Restart") { target = steps.first }
				.foregroundStyle(.white)
				.walkthroughTarget(.flowReset, horizontalPadding: .spacingM, verticalPadding: .spacingS)
		}
		.padding(.spacingL)
	}
	.walkthroughContainer(target: target) { id, _ in
		target = steps.drop { $0.id != id }.dropFirst().first
	}
}

private extension WalkthroughTarget {
	static let forYou: Self = .init(
		id: "for_you_chip",
		title: "For you",
		description: "Your suggested activities for today live here. Track your progress as you go.",
		action: "Got it"
	)

	static let flowForYou: Self = .init(
		id: "flow_for_you_chip",
		title: "For you",
		description: "Your suggested activities for today live here. Track your progress as you go.",
		action: "Next"
	)

	static let flowProfile: Self = .init(
		id: "flow_profile_avatar",
		title: "Your profile",
		description: "Find your account details and preferences here.",
		action: "Next"
	)

	static let flowDailyPlan: Self = .init(
		id: "flow_daily_plan_card",
		title: "Your daily plan",
		description: "Start today's activities from this card whenever you're ready.",
		action: "Next"
	)

	static let flowReset: Self = .init(
		id: "flow_reset",
		title: "Reset the flow",
		description: "With this button you can reset this preview flow",
		action: "Done"
	)
}
#endif
