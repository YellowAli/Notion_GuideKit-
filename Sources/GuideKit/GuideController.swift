import Foundation
import Observation
import CoreGraphics
import GuideKitCore

public struct GuidePresentation: Equatable {
    public var say: String
    public var stepIndex: Int
    public var stepCount: Int
    public var frame: CGRect?
}

public struct GuideStatus: Codable, Equatable {
    public var state: String
    public var flowID: String?
    public var target: String?
    public var stepIndex: Int?
    public var pick: Pick?
    public var failure: String?
    public var allFlowIDs: [String]

    public init(state: String, flowID: String? = nil, target: String? = nil, stepIndex: Int? = nil,
                pick: Pick? = nil, failure: String? = nil, allFlowIDs: [String]) {
        self.state = state
        self.flowID = flowID
        self.target = target
        self.stepIndex = stepIndex
        self.pick = pick
        self.failure = failure
        self.allFlowIDs = allFlowIDs
    }
}

@MainActor @Observable
public final class GuideController {
    public static let defaultTimeout: Duration = .seconds(5)

    public let flows: [Flow]
    public private(set) var presentation: GuidePresentation?
    public private(set) var status: GuideStatus

    @ObservationIgnored private var runtime = GuideRuntime()
    @ObservationIgnored private var prepares: [String: @MainActor () -> Void] = [:]
    @ObservationIgnored private var facts: [String: FactValue] = [:]
    @ObservationIgnored private var frames: [String: [CGRect]] = [:]
    @ObservationIgnored private var lastFlowID: String?
    @ObservationIgnored private let sleep: @Sendable (Duration) async -> Void
    @ObservationIgnored private(set) var pendingTimeouts: [Task<Void, Never>] = []

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

    public func start(flowID: String) {
        if case .waiting = runtime.state { return }
        guard let flow = flows.first(where: { $0.id == flowID }) else { return }
        prepares[flowID]?()
        lastFlowID = flowID
        send(.start(flow, targets: presentTargets, facts: facts))
    }

    public func cancel() { send(.cancel) }

    public func updateTargets(_ newFrames: [String: [CGRect]]) {
        let before = presentTargets
        frames = newFrames
        if presentTargets != before { send(.targetsChanged(presentTargets)) }
        refreshFrame()
    }

    public func reportFact(_ key: String, _ value: FactValue) {
        facts[key] = value
        send(.factsChanged(facts))
    }

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
