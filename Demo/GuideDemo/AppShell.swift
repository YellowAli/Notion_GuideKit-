import CalendarFeature
import DesignSystem
import EditorFeature
import SwiftUI
import Observation
import Foundation

/// A plain in-hierarchy tab bar, so guide targets in any screen reach the root host.
struct AppShell: View {
    let shell: ShellModel

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch shell.selectedTab {
                case .editor: EditorView(store: shell.blocks)
                case .calendar: CalendarView(store: shell.events)
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
                .accessibilityIdentifier("tab.\(tab.rawValue)")
                .accessibilityAddTraits(shell.selectedTab == tab ? .isSelected : [])
            }
        }
        .padding(.top, 4)
    }
}

@MainActor @Observable
final class ShellModel {
    var selectedTab: DemoTab = .editor
    /// Owned here so content survives switching tabs, while only the visible screen stays mounted.
    let blocks = BlockStore()
    let events = EventStore()
}

enum DemoTab: String, CaseIterable, Identifiable {
    case editor, calendar

    var id: String { rawValue }
    var title: String {
        switch self {
        case .editor: "Editor"
        case .calendar: "Calendar"
        }
    }
    var systemImage: String {
        switch self {
        case .editor: "doc.text"
        case .calendar: "calendar"
        }
    }
}
