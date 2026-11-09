import SwiftUI
import GuideKitCore

private struct GuideFactModifier: ViewModifier {
    @Environment(\.guideController) private var controller
    let key: String
    let value: FactValue

    func body(content: Content) -> some View {
        content
            // Each report goes to the controller, then the runtime re-checks the current step.
            .onAppear { controller?.reportFact(key, value) }
            .onChange(of: value) { _, new in controller?.reportFact(key, new) }
            .onDisappear { controller?.forgetFact(key) }
    }
}

extension View {
    /// Reports `value` under `key` on appear and whenever it changes, and forgets it on disappear.
    /// Reports a piece of app state that a walkthrough step can check.
    ///
    /// Use it when a step finishes because something changed rather than because something appeared, for example
    /// "the event count went up by one". The fact is reported when the view appears, again whenever `value` changes,
    /// and forgotten when the view disappears.
    ///
    /// ```swift
    /// CalendarList(events: store.events)
    ///     .guideFact("calendar.event.count", value: store.events.count)
    /// ```
    ///
    /// Attach it to a view that stays on screen for the whole step. Facts are stored by key, so if two views swap
    /// in and out under the same key, the outgoing view's disappearance can remove the fact the incoming view just
    /// reported, and it stays dropped until the value next changes.
    ///
    /// - Parameters:
    ///   - key: A dotted lowercase key such as `calendar.event.count`.
    ///   - value: The current value: a `Bool`, `Int` or `String`.
    ///
    /// Hands the value to `GuideController.reportFact`, which sends the runtime a `factsChanged` event.
    /// Design: docs/tdd/04-controller-and-modifiers.md
    public func guideFact(_ key: String, value: some GuideFactConvertible) -> some View {
        modifier(GuideFactModifier(key: key, value: value.guideFactValue))
    }
}
