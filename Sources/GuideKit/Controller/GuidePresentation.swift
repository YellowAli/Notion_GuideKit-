import Foundation
import CoreGraphics
import GuideKitCore

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
