import Foundation

public enum GuideFailure: Error, Equatable, CustomStringConvertible {
    case targetNotFound(flowID: String, step: Int, target: String)
    case factNeverReported(flowID: String, step: Int, key: String)
    case wrongFactType(flowID: String, step: Int, key: String)
    case checkNotPassed(flowID: String, step: Int)

    public var description: String {
        switch self {
        case .targetNotFound(let id, let step, let target):
            return "`\(id)` step \(step + 1): target `\(target)` not found"
        case .factNeverReported(let id, let step, let key):
            return "`\(id)` step \(step + 1): fact `\(key)` was never reported"
        case .wrongFactType(let id, let step, let key):
            return "`\(id)` step \(step + 1): fact `\(key)` has the wrong type for this check"
        case .checkNotPassed(let id, let step):
            return "`\(id)` step \(step + 1): completion check did not pass"
        }
    }
}

public enum GuideState: Equatable {
    case idle
    case waiting(flow: Flow, step: Int)
    case completed(flowID: String)
    case failed(GuideFailure)
}

public enum GuideEvent {
    case start(Flow, targets: Set<String>, facts: [String: FactValue])
    case factsChanged([String: FactValue])
    case targetsChanged(Set<String>)
    case targetTapped(String)
    case timeout(token: Int)
    case cancel
}

public enum GuideEffect: Equatable {
    case present(step: Int, Step)
    case dismiss
    case scheduleTimeout(token: Int)
}

/// Pure reducer deciding when each walkthrough step is complete.
public struct GuideRuntime {
    public private(set) var state: GuideState = .idle

    private var targets: Set<String> = []
    private var facts: [String: FactValue] = [:]
    private var baseline: Int?
    private var armed = true
    private var tapped = false
    private var lastToken = 0

    public init() {}

    public mutating func handle(_ event: GuideEvent) -> [GuideEffect] {
        switch event {
        case .start(let flow, let targets, let facts):
            if case .waiting = state { return [] }
            self.targets = targets
            self.facts = facts
            guard !flow.steps.isEmpty else {
                state = .completed(flowID: flow.id)
                return [.dismiss]
            }
            return enter(flow: flow, step: 0)

        case .cancel:
            guard case .waiting = state else { return [] }
            state = .idle
            return [.dismiss]

        case .factsChanged(let facts):
            guard case .waiting = state else { return [] }
            self.facts = facts
            return evaluate(tapOnTarget: false)

        case .targetsChanged(let targets):
            guard case .waiting = state else { return [] }
            self.targets = targets
            return evaluate(tapOnTarget: false)

        case .targetTapped(let name):
            guard case .waiting(let flow, let index) = state, flow.steps[index].target == name else {
                // A tap elsewhere can still satisfy nothing; `tapped` only counts the current target.
                return []
            }
            armed = true
            tapped = true
            let effects = evaluate(tapOnTarget: true)
            if case .waiting(_, let now) = state, now == index {
                return effects + [schedule()]
            }
            return effects

        case .timeout(let token):
            guard case .waiting(let flow, let index) = state, token == lastToken else { return [] }
            let step = flow.steps[index]
            if !targets.contains(step.target) {
                return fail(.targetNotFound(flowID: flow.id, step: index, target: step.target))
            }
            guard tapped else { return [] }
            switch step.completeWhen {
            case .factEquals(let key, _), .factIncreased(let key, _):
                if facts[key] == nil {
                    return fail(.factNeverReported(flowID: flow.id, step: index, key: key))
                }
            default:
                break
            }
            return fail(.checkNotPassed(flowID: flow.id, step: index))
        }
    }

    // MARK: - Private

    private mutating func schedule() -> GuideEffect {
        lastToken += 1
        return .scheduleTimeout(token: lastToken)
    }

    private mutating func fail(_ failure: GuideFailure) -> [GuideEffect] {
        state = .failed(failure)
        return [.dismiss]
    }

    private mutating func enter(flow: Flow, step index: Int) -> [GuideEffect] {
        let step = flow.steps[index]
        tapped = false
        baseline = nil
        if case .factIncreased(let key, _) = step.completeWhen, let value = facts[key] {
            guard case .int(let n) = value else {
                return fail(.wrongFactType(flowID: flow.id, step: index, key: key))
            }
            baseline = n
        }
        armed = !isSatisfiedAtEntry(step.completeWhen)
        state = .waiting(flow: flow, step: index)
        var effects: [GuideEffect] = [.present(step: index, step)]
        if !targets.contains(step.target) {
            effects.append(schedule())
        }
        return effects
    }

    private func isSatisfiedAtEntry(_ check: Check) -> Bool {
        switch check {
        case .targetVisible(let name): return targets.contains(name)
        case .factEquals(let key, let value): return facts[key] == value
        case .factIncreased, .tapped: return false
        }
    }

    private mutating func evaluate(tapOnTarget: Bool) -> [GuideEffect] {
        guard case .waiting(let flow, let index) = state, armed else { return [] }
        let check = flow.steps[index].completeWhen
        var passed = false
        switch check {
        case .targetVisible(let name):
            passed = targets.contains(name)
        case .factEquals(let key, let expected):
            if let value = facts[key] {
                if value == expected {
                    passed = true
                } else if !sameCase(value, expected) {
                    return fail(.wrongFactType(flowID: flow.id, step: index, key: key))
                }
            }
        case .factIncreased(let key, let by):
            if let value = facts[key] {
                guard case .int(let n) = value else {
                    return fail(.wrongFactType(flowID: flow.id, step: index, key: key))
                }
                if let base = baseline {
                    passed = n - base >= by
                } else {
                    baseline = n
                }
            }
        case .tapped:
            passed = tapOnTarget
        }
        guard passed else { return [] }
        if index + 1 < flow.steps.count {
            return enter(flow: flow, step: index + 1)
        }
        state = .completed(flowID: flow.id)
        return [.dismiss]
    }

    private func sameCase(_ a: FactValue, _ b: FactValue) -> Bool {
        switch (a, b) {
        case (.bool, .bool), (.int, .int), (.string, .string): return true
        default: return false
        }
    }
}
