import SwiftUI

private struct GuideControllerKey: EnvironmentKey {
    static let defaultValue: GuideController? = nil
}

extension EnvironmentValues {
    var guideController: GuideController? {
        get { self[GuideControllerKey.self] }
        set { self[GuideControllerKey.self] = newValue }
    }
}
