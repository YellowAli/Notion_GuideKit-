import Foundation
import Observation

public enum BlockKind: String, CaseIterable {
    case title, text, heading, todo, toggle
}

public struct Block: Identifiable, Equatable {
    public let id: UUID
    public var kind: BlockKind
    public var text: String
    /// Checked for a to-do, expanded for a toggle.
    public var isOn = false

    public init(id: UUID = UUID(), kind: BlockKind, text: String = "") {
        self.id = id
        self.kind = kind
        self.text = text
    }
}

@MainActor @Observable
public final class BlockStore {
    public var blocks: [Block] = [
        Block(kind: .title, text: "Getting started"),
        Block(kind: .text, text: "Press + to add a block."),
    ]

    public init() {}

    public func count(of kind: BlockKind) -> Int {
        blocks.filter { $0.kind == kind }.count
    }

    public func add(_ kind: BlockKind) {
        blocks.append(Block(kind: kind))
    }

    /// The title block keeps its kind.
    public func turnInto(_ kind: BlockKind, id: Block.ID) {
        guard let index = blocks.firstIndex(where: { $0.id == id }), blocks[index].kind != .title else { return }
        blocks[index].kind = kind
    }
}
