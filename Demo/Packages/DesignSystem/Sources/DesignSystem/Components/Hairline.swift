import SwiftUI

/// A one-point-or-thinner rule that stays crisp at every scale.
public struct Hairline: View {
    public init() {}

    public var body: some View {
        Theme.hairline.frame(height: 0.5)
    }
}
