import Foundation

public enum GuideEffect: Equatable {
    case present(step: Int, Step)
    case dismiss
    case scheduleTimeout(token: Int)
}
