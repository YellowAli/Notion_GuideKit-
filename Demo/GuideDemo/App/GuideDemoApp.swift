import EditorFeature
import CalendarFeature
import GuideKit
import SwiftUI

@main
struct GuideDemoApp: App {
    @State private var shell: ShellModel
    @State private var controller: GuideController

    init() {
        let shell = ShellModel()
        _shell = State(initialValue: shell)
        _controller = State(initialValue: GuideController(features: [
            EditorGuide.feature(prepare: {
                shell.selectedTab = .editor
                shell.blocks.closeMenus()
            }),
            CalendarGuide.feature(prepare: { shell.selectedTab = .calendar }),
        ]))
    }

    var body: some Scene {
        WindowGroup {
            AppShell(shell: shell)
                // Clears the tab bar and Calendar's form row, whose Save sits at the trailing edge.
                .guideHost(controller, launcherBottomClearance: 120)
                .preferredColorScheme(.light)
        }
    }
}
