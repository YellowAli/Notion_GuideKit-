import SwiftUI
import GuideKit

/// A quiet button. With an empty title and a `systemImage` it is an icon-only button.
///
/// Forwards `guideID` to `guideTarget`, so product code tags a control without importing GuideKit views.
/// Design: docs/tdd/06-shared-components-and-demo.md
public struct AppButton: View {
    private let title: String
    private let systemImage: String?
    private let guideID: String?
    private let action: () -> Void

    /// Creates a button.
    ///
    /// - Parameters:
    ///   - title: The label. Pass an empty string for an icon-only button.
    ///   - systemImage: An SF Symbol name shown before the title.
    ///   - guideID: A guide target ID for walkthroughs, forwarded to `guideTarget(_:)`. `nil` makes the button untagged.
    ///   - action: Runs when the button is tapped.
    public init(_ title: String, systemImage: String? = nil, guideID: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.guideID = guideID
        self.action = action
    }

    /// The button's content.
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(title.isEmpty ? Theme.icon : Theme.ink)
                }
                if !title.isEmpty {
                    Text(title).font(.system(size: 15, weight: .medium)).foregroundStyle(Theme.ink)
                }
            }
            .padding(.horizontal, title.isEmpty ? 8 : 10)
            .frame(minWidth: 36, minHeight: 36)
            .contentShape(Rectangle())
        }
        .buttonStyle(QuietButtonStyle())
        .accessibilityLabel(title.isEmpty ? Self.iconLabel(systemImage) : title)
        .guideTarget(guideID)
    }

    private static func iconLabel(_ systemImage: String?) -> String {
        switch systemImage {
        case "plus": return "Add block"
        case "ellipsis": return "Block options"
        case "xmark": return "Close"
        default: return systemImage ?? "Button"
        }
    }
}

private struct QuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Theme.pressed : .clear, in: RoundedRectangle(cornerRadius: Theme.radius))
    }
}
