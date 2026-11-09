import Foundation

public struct Step: Codable, Equatable, Sendable {
    public var target: String
    public var say: String
    public var pick: Pick
    public var completeWhen: Check

    public init(target: String, say: String, pick: Pick = .first, completeWhen: Check) {
        self.target = target
        self.say = say
        self.pick = pick
        self.completeWhen = completeWhen
    }

    private enum CodingKeys: String, CodingKey {
        case target, say, pick, completeWhen
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        target = try c.decode(String.self, forKey: .target)
        say = try c.decode(String.self, forKey: .say)
        pick = try c.decodeIfPresent(Pick.self, forKey: .pick) ?? .first
        completeWhen = try c.decode(Check.self, forKey: .completeWhen)
    }
}
