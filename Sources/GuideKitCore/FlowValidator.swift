import Foundation

/// A problem found while validating a flow. Its `description` is written for the flow's author.
public enum FlowValidationError: Error, Equatable, CustomStringConvertible {
    /// The flow has no steps.
    case emptyFlow(flowID: String)
    /// An ID, whether flow, target or fact key, is not dotted lowercase such as `team.feature`.
    case malformedID(String)
    /// Two flows in the same list share an ID.
    case duplicateFlowID(String)
    /// The flow ID does not start with the feature's namespace.
    case outsideNamespace(flowID: String, namespace: String)
    /// A step's `say` text is empty or only whitespace. `step` is zero-based.
    case emptyInstruction(flowID: String, step: Int)
    /// A `factIncreased` check asks for an increase of zero or less. `step` is zero-based.
    case invalidIncrement(flowID: String, step: Int)

    /// A sentence for the flow's author naming the flow and the one-based step.
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

/// Checks flows for mistakes that would otherwise only show up when someone runs the walkthrough.
///
/// `GuideFeature` runs this on every file it loads, so you rarely call it yourself. Use it directly to
/// validate flows built in code, for example in a unit test.
///
/// Called by `GuideFeature` for each flow file it loads, before the flow reaches `GuideController`.
/// Design: docs/tdd/02-validation-and-loading.md
public enum FlowValidator {
    private static let idPattern = "^[a-z][a-z0-9_]*(\\.[a-z][a-z0-9_]*)+$"

    private static func isWellFormed(_ id: String) -> Bool {
        id.range(of: idPattern, options: .regularExpression) != nil
    }

    /// Validates `flows` and returns every problem found.
    ///
    /// - Parameters:
    ///   - flows: The flows to check.
    ///   - namespace: The feature's namespace. Each flow ID must start with `namespace` followed by a dot.
    /// - Returns: The problems found, or an empty array if the flows are valid.
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
