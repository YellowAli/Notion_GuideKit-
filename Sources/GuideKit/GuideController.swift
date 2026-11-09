import Foundation
import Observation
import CoreGraphics
import GuideKitCore

/// The object an app creates once to run walkthroughs.
///
/// It owns the registered flows, receives target frames and facts from the SwiftUI modifiers, drives a
/// ``GuideRuntime`` and publishes what to show. Create one from every team's ``GuideFeature`` and attach it
/// to the root view with `guideHost(_:launcherBottomClearance:)`:
///
/// ```swift
/// let controller = GuideController(features: [
///     EditorGuide.feature(prepare: { shell.selectedTab = .editor }),
///     CalendarGuide.feature(prepare: { shell.selectedTab = .calendar }),
/// ])
///
/// AppShell(shell: shell)
///     .guideHost(controller)
/// ```
///
/// The controller is main-actor isolated and `@Observable`, so SwiftUI views can read ``presentation`` and ``status`` directly.
///
/// Receives frames, facts and taps from the modifiers, turns them into `GuideEvent`s for `GuideRuntime`,
/// and publishes `presentation` for `SpotlightOverlay` and `status` for tests.
/// Design: docs/tdd/04-controller-and-modifiers.md
@MainActor @Observable
public final class GuideController {
    /// How long a step waits for a missing target, or for a check to pass after a tap, before the walkthrough fails. Fixed at five seconds.
    public static let defaultTimeout: Duration = .seconds(5)

    /// Every registered flow, in registration order. When two features register the same flow ID, the first one wins.
    public let flows: [Flow]
    /// The step to display, or nil when no walkthrough is showing.
    public private(set) var presentation: GuidePresentation?
    /// A Codable snapshot of progress for tooling and UI tests.
    public private(set) var status: GuideStatus

    @ObservationIgnored private var runtime = GuideRuntime()
    @ObservationIgnored private var prepares: [String: @MainActor () -> Void] = [:]
    @ObservationIgnored private var facts: [String: FactValue] = [:]
    @ObservationIgnored private var frames: [String: [CGRect]] = [:]
    @ObservationIgnored private var lastFlowID: String?
    @ObservationIgnored private let sleep: @Sendable (Duration) async -> Void
    @ObservationIgnored private(set) var pendingTimeouts: [Task<Void, Never>] = []

    /// Creates a controller from the registered features.
    ///
    /// - Parameters:
    ///   - features: The features whose flows to offer. If two flows share an ID, the first feature's flow and `prepare` hook win.
    ///   - sleep: Waits for a duration before a timeout fires. Pass a fake in unit tests to make timeouts instant; the default uses `Task.sleep`.
    public init(features: [GuideFeature],
                sleep: @escaping @Sendable (Duration) async -> Void = { try? await Task.sleep(for: $0) }) {
        self.sleep = sleep
        var all: [Flow] = []
        var seen = Set<String>()
        var prepares: [String: @MainActor () -> Void] = [:]
        for feature in features {
            // The first feature to register an ID wins, including its prepare.
            for flow in feature.flows where seen.insert(flow.id).inserted {
                all.append(flow)
                prepares[flow.id] = feature.prepare
            }
        }
        flows = all
        self.prepares = prepares
        status = GuideStatus(state: "idle", allFlowIDs: all.map(\.id))
    }

    private func computeStatus() -> GuideStatus {
        let ids = flows.map(\.id)
        switch runtime.state {
        case .idle:
            return GuideStatus(state: "idle", allFlowIDs: ids)
        case .waiting(let flow, let step):
            return GuideStatus(state: "waiting", flowID: flow.id, target: flow.steps[step].target,
                               stepIndex: step, pick: flow.steps[step].pick, allFlowIDs: ids)
        case .completed(let id):
            return GuideStatus(state: "completed", flowID: id, allFlowIDs: ids)
        case .failed(let failure):
            return GuideStatus(state: "failed", flowID: lastFlowID, failure: failure.description, allFlowIDs: ids)
        }
    }

    /// Starts a flow after running its feature's `prepare` hook.
    ///
    /// Does nothing if a walkthrough is already running or no registered flow has this ID.
    ///
    /// - Parameters:
    ///   - flowID: The ID of a registered flow.
    public func start(flowID: String) {
        if case .waiting = runtime.state { return }
        guard let flow = flows.first(where: { $0.id == flowID }) else { return }
        prepares[flowID]?()
        lastFlowID = flowID
        send(.start(flow, targets: presentTargets, facts: facts))
    }

    /// Stops the running walkthrough and hides the overlay. Does nothing if none is running.
    public func cancel() { send(.cancel) }

    /// Supplies the current frames of every tagged view. The host calls this for you.
    ///
    /// A target with no frames counts as absent.
    ///
    /// - Parameters:
    ///   - newFrames: Frames keyed by guide ID. Several frames under one ID are in layout order.
    public func updateTargets(_ newFrames: [String: [CGRect]]) {
        let before = presentTargets
        frames = newFrames
        if presentTargets != before { send(.targetsChanged(presentTargets)) }
        refreshFrame()
    }

    /// Records a fact and re-evaluates the current step. `guideFact(_:value:)` calls this for you.
    ///
    /// - Parameters:
    ///   - key: The fact key.
    ///   - value: Its current value.
    public func reportFact(_ key: String, _ value: FactValue) {
        facts[key] = value
        send(.factsChanged(facts))
    }

    /// Drops a fact whose reporting view went away, so a stale value can't become a step's baseline.
    /// Drops a fact whose reporting view went away, so a stale value can't become a step's baseline.
    ///
    /// - Parameters:
    ///   - key: The fact key to remove.
    public func forgetFact(_ key: String) {
        facts[key] = nil
        send(.factsChanged(facts))
    }

    /// Tells the controller a tagged view was tapped. `guideTarget(_:)` calls this for you.
    ///
    /// - Parameters:
    ///   - id: The tapped view's guide ID.
    public func reportTap(_ id: String) { send(.targetTapped(id)) }

    // MARK: - Private

    /// A target with no frames counts as absent.
    private var presentTargets: Set<String> {
        Set(frames.filter { !$0.value.isEmpty }.keys)
    }

    private func send(_ event: GuideEvent) {
        defer {
            let latest = computeStatus()
            if latest != status { status = latest }
        }
        // The runtime decides what happens; this loop only performs its effects (show or hide, start a timer).
        for effect in runtime.handle(event) {
            switch effect {
            case .present(let index, let step):
                guard case .waiting(let flow, _) = runtime.state else { continue }
                presentation = GuidePresentation(say: step.say, stepIndex: index, stepCount: flow.steps.count,
                                                 frame: frame(for: step))
            case .dismiss:
                presentation = nil
                pendingTimeouts.forEach { $0.cancel() }
                pendingTimeouts = []
            case .scheduleTimeout(let token):
                let sleep = self.sleep
                pendingTimeouts.append(Task { [weak self] in
                    await sleep(Self.defaultTimeout)
                    guard !Task.isCancelled else { return }
                    self?.send(.timeout(token: token))
                })
            }
        }
    }

    private func frame(for step: Step) -> CGRect? {
        guard let rects = frames[step.target], !rects.isEmpty else { return nil }
        return step.pick == .first ? rects.first : rects.last
    }

    private func refreshFrame() {
        guard var current = presentation, case .waiting(let flow, let index) = runtime.state else { return }
        current.frame = frame(for: flow.steps[index])
        if current != presentation { presentation = current }
    }
}

/// What the overlay shows right now: one step of a running walkthrough. `nil` on ``GuideController/presentation`` means nothing is shown.
public struct GuidePresentation: Equatable {
    /// The instruction text for the current step.
    public var say: String
    /// The zero-based index of the current step.
    public var stepIndex: Int
    /// The number of steps in the flow.
    public var stepCount: Int
    /// The highlighted view's frame in the host's coordinate space, or nil while the target is not on screen.
    public var frame: CGRect?
}
