import SwiftUI
import GuideKit

/// A quiet button. With an empty title and a `systemImage` it is an icon-only button.
public struct AppButton: View {
    private let title: String
    private let systemImage: String?
    private let guideID: String?
    private let action: () -> Void

    public init(_ title: String, systemImage: String? = nil, guideID: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.guideID = guideID
        self.action = action
    }

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
