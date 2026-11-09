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

    /// The block menu, and the turn-into panel's block. Kept here so a walkthrough can reset them.
    public var menuOpen = false
    public var turnIntoBlock: Block.ID?

    public init() {}

    /// Closes the block menu and any turn-into panel, so a walkthrough begins from a known state.
    public func closeMenus() {
        menuOpen = false
        turnIntoBlock = nil
    }

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
