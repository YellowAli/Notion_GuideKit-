import XCTest
@testable import EditorFeature

@MainActor
final class BlockStoreTests: XCTestCase {
    func testSeededWithTitleAndText() {
        let store = BlockStore()
        XCTAssertEqual(store.blocks.map(\.kind), [.title, .text])
    }

    func testAddBlockIncrementsCount() {
        let store = BlockStore()
        store.add(.heading)
        store.add(.heading)
        store.add(.todo)
        XCTAssertEqual(store.count(of: .heading), 2)
        XCTAssertEqual(store.count(of: .todo), 1)
        XCTAssertEqual(store.blocks.last?.kind, .todo)
    }

    func testTurnIntoChangesKind() throws {
        let store = BlockStore()
        let text = try XCTUnwrap(store.blocks.last)
        store.turnInto(.toggle, id: text.id)
        XCTAssertEqual(store.count(of: .toggle), 1)
        XCTAssertEqual(store.count(of: .text), 0)
    }

    func testTitleCannotBeTurnedIntoAnotherKind() throws {
        let store = BlockStore()
        let title = try XCTUnwrap(store.blocks.first)
        store.turnInto(.toggle, id: title.id)
        XCTAssertEqual(store.blocks.first?.kind, .title)
    }

    func testEditorFlowsValidate() {
        let feature = EditorGuide.feature(prepare: {})
        XCTAssertEqual(feature.loadErrors, [])
        XCTAssertEqual(feature.flows.map(\.id),
                       ["editor.add_heading", "editor.add_todo", "editor.find_share", "editor.turn_into_toggle"])
    }

    func testCloseMenusClearsMenuAndPanel() {
        let store = BlockStore()
        store.menuOpen = true
        store.turnIntoBlock = store.blocks[0].id
        store.closeMenus()
        XCTAssertFalse(store.menuOpen)
        XCTAssertNil(store.turnIntoBlock)
    }
}
