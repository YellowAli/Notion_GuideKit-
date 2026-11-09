import Foundation

/// Pure reducer deciding when each walkthrough step is complete.
/// A pure state machine that decides when each walkthrough step is complete.
///
/// It has no UI, clock or threading of its own: feed it ``GuideEvent`` values and it returns ``GuideEffect``
/// values for the caller to perform. That makes every rule testable without a simulator.
/// `GuideController` is the production caller; use the runtime directly only to test or embed it elsewhere.
///
/// ```swift
/// var runtime = GuideRuntime()
/// _ = runtime.handle(.start(flow, targets: ["calendar.new_event"], facts: [:]))
/// _ = runtime.handle(.targetTapped("calendar.new_event"))
/// ```
///
/// Sits between `GuideController` (sends events, performs effects) and the flow model it walks through.
/// Design: docs/tdd/03-runtime.md
public struct GuideRuntime {
    /// The current state. It changes only inside ``handle(_:)``.
    public private(set) var state: GuideState = .idle

    private var targets: Set<String> = []
    private var facts: [String: FactValue] = [:]
    /// For `factIncreased`: the value the fact had when the step began, or when it was first reported.
    private var baseline: Int?
    /// Whether the check may complete the step. A check that is already true when the step appears (a menu
    /// that is already open, a fact that already equals the goal) would skip the step before the person did
    /// anything, so it starts disarmed. It arms when the person taps the target, or when a late-arriving
    /// target is first shown and the check is not already true at that moment.
    private var armed = true
    /// Whether the person has tapped the current step's target. After a tap, a missing result is a real
    /// failure; before one, a missing target may just be slow to render.
    private var tapped = false
    private var lastToken = 0
    /// Identifies the one outstanding timer. Timers cannot be recalled once scheduled, so a stale timeout
    /// (from a step already left, or a target that came back) is recognized by its old token and ignored.
    /// nil when no timer is outstanding.
    private var activeToken: Int?

    /// Creates an idle runtime.
    public init() {}

    /// Applies one event and returns the effects the caller must perform, in order.
    ///
    /// - Parameters:
    ///   - event: What just happened on screen.
    /// - Returns: Effects to carry out. Empty when the event changed nothing.
    public mutating func handle(_ event: GuideEvent) -> [GuideEffect] {
        switch event {
        case .start(let flow, let targets, let facts):
            if case .waiting = state { return [] }
            self.targets = targets
            self.facts = facts
            guard !flow.steps.isEmpty else {
                state = .completed(flowID: flow.id)
                activeToken = nil
                return [.dismiss]
            }
            return enter(flow: flow, step: 0)

        case .cancel:
            guard case .waiting = state else { return [] }
            state = .idle
            activeToken = nil
            return [.dismiss]

        case .factsChanged(let facts):
            guard case .waiting(let flow, let index) = state else { return [] }
            self.facts = facts
            // A fact that went away has no meaningful baseline; the next report sets a new one.
            if case .factIncreased(let key, _) = flow.steps[index].completeWhen, facts[key] == nil {
                baseline = nil
            }
            return evaluate(tapOnTarget: false)

        case .targetsChanged(let targets):
            guard case .waiting(let flow, let index) = state else { return [] }
            let step = flow.steps[index]
            let wasPresent = self.targets.contains(step.target)
            let isPresent = targets.contains(step.target)
            self.targets = targets
            // A target arriving late is the first time the step is really shown, so judge "already true" now.
            if !wasPresent && isPresent && !tapped {
                armed = !isSatisfiedAtEntry(step.completeWhen)
            }
            let before = state
            var effects = evaluate(tapOnTarget: false)
            // Before a tap, a vanishing target starts a timer and a returning one cancels it.
            if state == before && !tapped {
                if wasPresent && !isPresent {
                    effects.append(schedule())
                } else if !wasPresent && isPresent {
                    activeToken = nil
                }
            }
            return effects

        case .targetTapped(let name):
            guard case .waiting(let flow, let index) = state, flow.steps[index].target == name else {
                // Only a tap on the current step's target counts.
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
            guard case .waiting(let flow, let index) = state, token == activeToken else { return [] }
            let step = flow.steps[index]
            guard tapped else {
                if !targets.contains(step.target) {
                    return fail(.targetNotFound(flowID: flow.id, step: index, target: step.target))
                }
                return []
            }
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

    /// Timers run in two situations only: a target is absent (on entering a step, or after it vanishes before
    /// the tap), and after the person taps the target but the check has not yet passed. Each gives the UI
    /// time to settle before the walkthrough is declared failed.
    private mutating func schedule() -> GuideEffect {
        lastToken += 1
        activeToken = lastToken
        return .scheduleTimeout(token: lastToken)
    }

    private mutating func fail(_ failure: GuideFailure) -> [GuideEffect] {
        state = .failed(failure)
        activeToken = nil
        return [.dismiss]
    }

    private mutating func enter(flow: Flow, step index: Int) -> [GuideEffect] {
        let step = flow.steps[index]
        tapped = false
        activeToken = nil
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
        activeToken = nil
        return [.dismiss]
    }

    private func sameCase(_ a: FactValue, _ b: FactValue) -> Bool {
        switch (a, b) {
        case (.bool, .bool), (.int, .int), (.string, .string): return true
        default: return false
        }
    }
}
