import SwiftUI
import DesignSystem
import EditorFeature
import GuideKit

enum DemoTab: String, CaseIterable, Identifiable {
    case editor

    var id: String { rawValue }
    var title: String { "Editor" }
    var systemImage: String { "doc.text" }
}

@MainActor @Observable
final class ShellModel {
    var selectedTab: DemoTab = .editor
}

@main
struct GuideDemoApp: App {
    @State private var shell: ShellModel
    @State private var controller: GuideController

    init() {
        let shell = ShellModel()
        _shell = State(initialValue: shell)
        _controller = State(initialValue: GuideController(features: [
            EditorGuide.feature(prepare: { shell.selectedTab = .editor }),
        ]))
    }

    var body: some Scene {
        WindowGroup {
            AppShell(shell: shell)
                .guideHost(controller)
                .preferredColorScheme(.light)
        }
    }
}

/// A plain in-hierarchy tab bar, so guide targets in any screen reach the root host.
struct AppShell: View {
    let shell: ShellModel

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch shell.selectedTab {
                case .editor: EditorView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            Hairline()
            tabBar
            Text("Unofficial concept demo, not affiliated with Notion.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.secondary)
                .padding(.bottom, 6)
        }
        .background(Theme.page)
    }

    private var tabBar: some View {
        HStack {
            ForEach(DemoTab.allCases) { tab in
                Button { shell.selectedTab = tab } label: {
                    VStack(spacing: 2) {
                        Image(systemName: tab.systemImage).font(.system(size: 18))
                        Text(tab.title).font(.system(size: 10))
                    }
                    .foregroundStyle(shell.selectedTab == tab ? Theme.ink : Theme.icon)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(shell.selectedTab == tab ? .isSelected : [])
            }
        }
        .padding(.top, 4)
    }
}
