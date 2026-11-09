import Foundation

public struct Flow: Codable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var steps: [Step]

    public init(id: String, title: String, steps: [Step]) {
        self.id = id
        self.title = title
        self.steps = steps
    }
}
