import Foundation
import GuideKitCore

/// A team's registration: its flows, loaded from the bundle, plus a hook that shows the right screen.
public struct GuideFeature {
    public var flows: [Flow]
    public var loadErrors: [String]
    let prepare: @MainActor () -> Void

    public init(namespace: String, bundle: Bundle, prepare: @escaping @MainActor () -> Void = {}) {
        let urls = bundle.urls(forResourcesWithExtension: "json", subdirectory: "flows") ?? []
        let loaded = Self.load(urls: urls, namespace: namespace)
        self.flows = loaded.flows.sorted { $0.id < $1.id }
        self.loadErrors = loaded.errors
        self.prepare = prepare
        if !loaded.errors.isEmpty {
            assertionFailure("GuideKit flow errors:\n" + loaded.errors.joined(separator: "\n"))
        }
    }

    init(flows: [Flow], prepare: @escaping @MainActor () -> Void = {}) {
        self.flows = flows
        self.loadErrors = []
        self.prepare = prepare
    }

    /// Loads one flow per file. A file that fails to decode or validate contributes an error and no flow.
    static func load(urls: [URL], namespace: String) -> (flows: [Flow], errors: [String]) {
        var flows: [Flow] = []
        var errors: [String] = []
        for url in urls {
            do {
                let flow = try JSONDecoder().decode(Flow.self, from: Data(contentsOf: url))
                let problems = FlowValidator.validate([flow], namespace: namespace)
                if problems.isEmpty {
                    flows.append(flow)
                } else {
                    errors.append(contentsOf: problems.map { "\(url.lastPathComponent): \($0.description)" })
                }
            } catch {
                errors.append("\(url.lastPathComponent): \(error)")
            }
        }
        return (flows, errors)
    }
}
