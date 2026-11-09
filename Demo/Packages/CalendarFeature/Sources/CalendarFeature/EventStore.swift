import Foundation
import Observation

public struct CalendarEvent: Identifiable, Equatable {
    public let id: UUID
    public var title: String

    public init(id: UUID = UUID(), title: String) {
        self.id = id
        self.title = title
    }
}

@MainActor @Observable
public final class EventStore {
    public nonisolated static let defaultTitle = "New event"

    public var events: [CalendarEvent] = [
        CalendarEvent(title: "Team sync"),
    ]

    public init() {}

    public func addEvent(title: String = EventStore.defaultTitle) {
        events.append(CalendarEvent(title: title))
    }
}
