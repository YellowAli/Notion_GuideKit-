import Foundation
import CoreGraphics
import GuideKitCore

public struct GuidePresentation: Equatable {
    public var say: String
    public var stepIndex: Int
    public var stepCount: Int
    public var frame: CGRect?
}
