import SwiftUI

/// Publishes `controller.status` as JSON so UI tests can follow a walkthrough from another process.
struct GuideStatusElement: View {
    let controller: GuideController

    private var json: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(controller.status) else { return "" }
        return String(decoding: data, as: UTF8.self)
    }

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .allowsHitTesting(false)
            .accessibilityElement()
            .accessibilityIdentifier("guidekit.status")
            .accessibilityValue(json)
    }
}
