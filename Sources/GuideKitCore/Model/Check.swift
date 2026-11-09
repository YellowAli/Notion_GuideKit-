import Foundation

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
