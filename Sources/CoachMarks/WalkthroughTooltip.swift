import SwiftUI
import UIDefinition

public struct WalkthroughTooltip: View {
	let target: WalkthroughTarget
	let arrowX: CGFloat
	let arrowEdge: VerticalEdge
	let action: () -> Void

	public init(
		target: WalkthroughTarget,
		arrowX: CGFloat,
		arrowEdge: VerticalEdge,
		action: @escaping () -> Void
	) {
		self.target = target
		self.arrowX = arrowX
		self.arrowEdge = arrowEdge
		self.action = action
	}

	public var body: some View {
		content
			.padding(.top, .spacingL)
			.padding(.horizontal, .spacingL)
			.padding(.bottom, .spacingS)
			.padding(arrowEdge == .top ? .top : .bottom, .arrowHeight)
			.frame(width: .tooltipWidth)
			.background {
				TooltipShape(arrowX: arrowX, arrowEdge: arrowEdge)
					.fill(.white)
					.shadow(.y8)
			}
	}

	private var content: some View {
		VStack(alignment: .leading, spacing: .spacingS) {
			Text(target.title)
				.font(.custom(ofType: .semibold, size: .t2))
				.foregroundStyle(Color.grey800)

			Text(target.description)
				.font(.custom(ofType: .regular, size: .t2))
				.foregroundStyle(Color.grey800)
				.fixedSize(horizontal: false, vertical: true)

			Capsule()
				.fill(Color.tooltipDivider)
				.frame(height: .tooltipDividerHeight)

			HStack(spacing: .zero) {
				Spacer()

				Button(target.action, action: action)
					.font(.custom(ofType: .semibold, size: .t3))
					.foregroundStyle(Color.grey900)
					.frame(minWidth: .buttonMinWidth, minHeight: .buttonMinHeight)
			}
		}
	}
}

struct TooltipShape: Shape {
	var arrowX: CGFloat
	let arrowEdge: VerticalEdge

	var animatableData: CGFloat {
		get { arrowX }
		set { arrowX = newValue }
	}

	func path(in rect: CGRect) -> Path {
		let top = rect.minY + .arrowHeight
		let radius = min(.radiusL, (rect.height - .arrowHeight) / 2, rect.width / 2)
		let leadingMaxPoint = max(rect.minX + arrowX, rect.minX + radius + .arrowWidth / 2)
		let arrowCenter = min(leadingMaxPoint, rect.maxX - radius - .arrowWidth / 2)

		var path = Path()

		// Top-left corner
		path.move(to: CGPoint(x: rect.minX, y: top + radius))
		path.addQuadCurve(
			to: CGPoint(x: rect.minX + radius, y: top),
			control: CGPoint(x: rect.minX, y: top)
		)

		// Top edge and arrow
		path.addLine(to: CGPoint(x: arrowCenter - .arrowWidth / 2, y: top))
		path.addLine(to: CGPoint(x: arrowCenter, y: rect.minY))
		path.addLine(to: CGPoint(x: arrowCenter + .arrowWidth / 2, y: top))

		// Top-right corner
		path.addLine(to: CGPoint(x: rect.maxX - radius, y: top))
		path.addQuadCurve(
			to: CGPoint(x: rect.maxX, y: top + radius),
			control: CGPoint(x: rect.maxX, y: top)
		)

		// Bottom-right corner
		path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
		path.addQuadCurve(
			to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
			control: CGPoint( x: rect.maxX, y: rect.maxY)
		)

		// Bottom-left corner
		path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
		path.addQuadCurve(
			to: CGPoint(x: rect.minX, y: rect.maxY - radius),
			control: CGPoint(x: rect.minX, y: rect.maxY)
		)

		path.closeSubpath()

		guard arrowEdge == .bottom else { return path }

		let verticalFlip = CGAffineTransform(translationX: 0, y: rect.minY + rect.maxY).scaledBy(x: 1, y: -1)
		return path.applying(verticalFlip)
	}
}

// MARK: - Constants
private extension CGFloat {
	static let tooltipDividerHeight: Self = 2
	static let buttonMinWidth: Self = 64
	static let buttonMinHeight: Self = 32
	static let arrowHeight: Self = 8
	static let arrowWidth: Self = 8.5
}

extension CGFloat {
	static let tooltipWidth: Self = 260
}

private extension Color {
	static let tooltipDivider: Self = .grey900.opacity(0.08)
}

// MARK: - Previews
#if DEBUG
#Preview {
	ZStack {
		Color.grey300.ignoresSafeArea()

		WalkthroughTooltip(
			target: .init(id: "1", title: "Tool tip", description: "This is a walkthrought description", action: "Done"),
			arrowX: .tooltipWidth * 0.85,
			arrowEdge: .top
		) {}
	}
}
#endif
