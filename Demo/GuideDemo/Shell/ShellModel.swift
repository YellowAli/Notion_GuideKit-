import CalendarFeature
import EditorFeature
import Observation

@MainActor @Observable
final class ShellModel {
    var selectedTab: DemoTab = .editor
    /// Owned here so content survives switching tabs, while only the visible screen stays mounted.
    let blocks = BlockStore()
    let events = EventStore()
}
