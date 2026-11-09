import SwiftUI
import GuideKit

/// One row in an in-hierarchy menu: a small gray icon and a title.
///
/// Design: docs/tdd/06-shared-components-and-demo.md
public struct AppMenuRow: View {
    private let title: String
    private let systemImage: String
    private let guideID: String?
    private let action: () -> Void

    /// Creates a menu row.
    ///
    /// - Parameters:
    ///   - title: The row's label.
    ///   - systemImage: An SF Symbol name for the leading icon.
    ///   - guideID: A guide target ID for walkthroughs, forwarded to `guideTarget(_:)`. `nil` makes the row untagged.
    ///   - action: Runs when the row is tapped.
    public init(_ title: String, systemImage: String, guideID: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.guideID = guideID
        self.action = action
    }

    /// The row's content.
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.icon)
                    .frame(width: 24)
                Text(title).font(.system(size: 16)).foregroundStyle(Theme.ink)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Theme.margin)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .guideTarget(guideID)
    }
}
