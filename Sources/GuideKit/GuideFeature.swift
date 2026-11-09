import Foundation
import GuideKitCore

/// A team's registration: its flows, loaded from the bundle, plus a hook that shows the right screen.
/// A team's registration: its flows, loaded from the bundle, plus a hook that shows the right screen.
///
/// Each feature package exposes one, so the app never touches the package's bundle:
///
/// ```swift
/// public enum CalendarGuide {
///     @MainActor
///     public static func feature(prepare: @escaping @MainActor () -> Void) -> GuideFeature {
///         GuideFeature(namespace: "calendar", bundle: .module, prepare: prepare)
///     }
/// }
/// ```
///
/// The package must bundle its flows as a folder: `resources: [.copy("Resources/flows")]`.
/// `.process` flattens the folder and the flows are not found.
///
/// Files that fail to decode or validate are skipped and described in ``loadErrors``. In debug builds
/// the initializer also stops with an assertion failure so the mistake is hard to miss.
///
/// Design: docs/tdd/02-validation-and-loading.md
public struct GuideFeature {
    /// The flows that loaded successfully, sorted by ID.
    public var flows: [Flow]
    /// One message per file or problem that kept a flow from loading. Empty when everything loaded.
    public var loadErrors: [String]
    let prepare: @MainActor () -> Void

    /// Loads every `.json` file in the bundle's `flows` folder.
    ///
    /// - Parameters:
    ///   - namespace: The prefix every flow ID must start with, such as `calendar`.
    ///   - bundle: The bundle holding the `flows` folder. In a Swift package use `.module`.
    ///   - prepare: Runs on the main actor just before one of this feature's flows starts. Use it to switch to the right screen and close any transient UI such as menus, so the flow starts from a known state.
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
        var seen = Set<String>()
        guard !urls.isEmpty else {
            return ([], ["No flow files found for namespace `\(namespace)`. Bundle a `flows` folder with resources: [.copy(\"Resources/flows\")]."])
        }
        for url in urls.sorted(by: { $0.path < $1.path }) {
            do {
                let flow = try JSONDecoder().decode(Flow.self, from: Data(contentsOf: url))
                let problems = FlowValidator.validate([flow], namespace: namespace)
                if !problems.isEmpty {
                    errors.append(contentsOf: problems.map { "\(url.lastPathComponent): \($0.description)" })
                } else if !seen.insert(flow.id).inserted {
                    errors.append("\(url.lastPathComponent): \(FlowValidationError.duplicateFlowID(flow.id).description)")
                } else {
                    flows.append(flow)
                }
            } catch {
                errors.append("\(url.lastPathComponent): \(error)")
            }
        }
        return (flows, errors)
    }
}
