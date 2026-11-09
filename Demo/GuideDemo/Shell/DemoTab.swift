import Foundation

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
