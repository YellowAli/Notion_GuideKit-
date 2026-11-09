import Foundation
import GuideKit

public enum CalendarGuide {
    @MainActor
    public static func feature(prepare: @escaping @MainActor () -> Void) -> GuideFeature {
        GuideFeature(namespace: "calendar", bundle: .module, prepare: prepare)
    }
}
