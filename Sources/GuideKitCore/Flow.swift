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

public enum Pick: String, Codable, Sendable {
    case first, last
}

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

public enum FactValue: Codable, Equatable, Sendable {
    case bool(Bool)
    case int(Int)
    case string(String)

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let b = try? c.decode(Bool.self) {
            self = .bool(b)
        } else if let i = try? c.decode(Int.self) {
            self = .int(i)
        } else if let s = try? c.decode(String.self) {
            self = .string(s)
        } else {
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "FactValue must be a bool, int, or string")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .bool(let b): try c.encode(b)
        case .int(let i): try c.encode(i)
        case .string(let s): try c.encode(s)
        }
    }
}

public enum Check: Codable, Equatable, Sendable {
    case targetVisible(String)
    case factEquals(key: String, value: FactValue)
    case factIncreased(key: String, by: Int)
    case tapped

    private enum CodingKeys: String, CodingKey {
        case targetVisible, fact, equals, increasedBy, tapped
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let target = try c.decodeIfPresent(String.self, forKey: .targetVisible) {
            self = .targetVisible(target)
        } else if let key = try c.decodeIfPresent(String.self, forKey: .fact) {
            if c.contains(.equals) {
                self = .factEquals(key: key, value: try c.decode(FactValue.self, forKey: .equals))
            } else if c.contains(.increasedBy) {
                self = .factIncreased(key: key, by: try c.decode(Int.self, forKey: .increasedBy))
            } else {
                throw DecodingError.dataCorruptedError(forKey: .fact, in: c, debugDescription: "fact check needs equals or increasedBy")
            }
        } else if try c.decodeIfPresent(Bool.self, forKey: .tapped) == true {
            self = .tapped
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown check shape"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .targetVisible(let t): try c.encode(t, forKey: .targetVisible)
        case .factEquals(let key, let value):
            try c.encode(key, forKey: .fact)
            try c.encode(value, forKey: .equals)
        case .factIncreased(let key, let by):
            try c.encode(key, forKey: .fact)
            try c.encode(by, forKey: .increasedBy)
        case .tapped: try c.encode(true, forKey: .tapped)
        }
    }
}
