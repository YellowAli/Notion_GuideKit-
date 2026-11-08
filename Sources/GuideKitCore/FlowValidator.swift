import Foundation

public enum FlowValidationError: Error, Equatable, CustomStringConvertible {
    case emptyFlow(flowID: String)
    case malformedID(String)
    case duplicateFlowID(String)
    case outsideNamespace(flowID: String, namespace: String)
    case emptyInstruction(flowID: String, step: Int)
    case invalidIncrement(flowID: String, step: Int)

    public var description: String {
        switch self {
        case .emptyFlow(let id): return "Flow \(id) has no steps."
        case .malformedID(let id): return "\"\(id)\" is not a valid ID (use dotted lowercase like team.feature)."
        case .duplicateFlowID(let id): return "Flow ID \(id) is used more than once."
        case .outsideNamespace(let id, let ns): return "Flow \(id) must start with \"\(ns).\"."
        case .emptyInstruction(let id, let step): return "Flow \(id), step \(step + 1) has an empty instruction."
        case .invalidIncrement(let id, let step): return "Flow \(id), step \(step + 1) must increase by more than 0."
        }
    }
}

public enum FlowValidator {
    private static let idPattern = "^[a-z][a-z0-9_]*(\\.[a-z][a-z0-9_]*)+$"

    private static func isWellFormed(_ id: String) -> Bool {
        id.range(of: idPattern, options: .regularExpression) != nil
    }

    public static func validate(_ flows: [Flow], namespace: String) -> [FlowValidationError] {
        var errors: [FlowValidationError] = []
        var seen = Set<String>()
        var reportedDuplicates = Set<String>()

        func checkID(_ id: String) {
            if !isWellFormed(id) { errors.append(.malformedID(id)) }
        }

        for flow in flows {
            if !seen.insert(flow.id).inserted, reportedDuplicates.insert(flow.id).inserted {
                errors.append(.duplicateFlowID(flow.id))
            }
            if !isWellFormed(flow.id) {
                errors.append(.malformedID(flow.id))
            } else if !flow.id.hasPrefix(namespace + ".") {
                errors.append(.outsideNamespace(flowID: flow.id, namespace: namespace))
            }
            if flow.steps.isEmpty { errors.append(.emptyFlow(flowID: flow.id)) }

            for (index, step) in flow.steps.enumerated() {
                checkID(step.target)
                if step.say.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    errors.append(.emptyInstruction(flowID: flow.id, step: index))
                }
                switch step.completeWhen {
                case .targetVisible(let name): checkID(name)
                case .factEquals(let key, _): checkID(key)
                case .factIncreased(let key, let by):
                    checkID(key)
                    if by <= 0 { errors.append(.invalidIncrement(flowID: flow.id, step: index)) }
                case .tapped: break
                }
            }
        }
        return errors
    }
}
