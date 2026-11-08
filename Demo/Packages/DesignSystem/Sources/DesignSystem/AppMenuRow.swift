import SwiftUI
import GuideKit

/// One row in an in-hierarchy menu: a small gray icon and a title.
public struct AppMenuRow: View {
    private let title: String
    private let systemImage: String
    private let guideID: String?
    private let action: () -> Void

    public init(_ title: String, systemImage: String, guideID: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.guideID = guideID
        self.action = action
    }

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
