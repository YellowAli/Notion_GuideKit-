import Foundation

public enum GuideEvent {
    case start(Flow, targets: Set<String>, facts: [String: FactValue])
    case factsChanged([String: FactValue])
    case targetsChanged(Set<String>)
    case targetTapped(String)
    case timeout(token: Int)
    case cancel
}
