import Foundation
import GuideKit

public enum EditorGuide {
    @MainActor
    public static func feature(prepare: @escaping @MainActor () -> Void) -> GuideFeature {
        GuideFeature(namespace: "editor", bundle: .module, prepare: prepare)
    }
}
