import SwiftUI
import DesignSystem
import GuideKit

public struct EditorView: View {
    @State private var store = BlockStore()
    @State private var menuOpen = false
    @State private var turnIntoBlock: Block.ID?
    @State private var showShared = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            header
            Hairline()
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach($store.blocks) { $block in
                        blockRow($block)
                        if turnIntoBlock == block.id { turnIntoPanel(for: block.id) }
                    }
                }
                .padding(.vertical, 16)
            }
            if menuOpen { blockMenu }
            Hairline()
            toolbar
        }
        .background(Theme.page)
        .guideFact("editor.heading.count", value: store.count(of: .heading))
        .guideFact("editor.todo.count", value: store.count(of: .todo))
        .guideFact("editor.toggle.count", value: store.count(of: .toggle))
    }

    // MARK: - Header and toolbar

    private var header: some View {
        HStack {
            Text("Getting started").font(.system(size: 14)).foregroundStyle(Theme.secondary)
            Spacer()
            if showShared {
                Text("Link copied").font(.system(size: 13)).foregroundStyle(Theme.secondary)
            }
            AppButton("Share", systemImage: "square.and.arrow.up", guideID: "editor.share_button") {
                showShared = true
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    showShared = false
                }
            }
        }
        .padding(.horizontal, Theme.margin - 8)
        .frame(minHeight: 44)
    }

    private var toolbar: some View {
        HStack {
            AppButton("", systemImage: "plus", guideID: "editor.add_block_button") {
                turnIntoBlock = nil
                menuOpen.toggle()
            }
            Spacer()
        }
        .padding(.horizontal, Theme.margin - 8)
        .frame(minHeight: 44)
    }

    // MARK: - Menus

    private var blockMenu: some View {
        VStack(spacing: 0) {
            Hairline()
            AppMenuRow("Heading", systemImage: "textformat.size", guideID: "editor.block_menu_heading") { add(.heading) }
            AppMenuRow("To-do", systemImage: "checkmark.square", guideID: "editor.block_menu_todo") { add(.todo) }
            AppMenuRow("Toggle", systemImage: "chevron.right.circle", guideID: "editor.block_menu_toggle") { add(.toggle) }
        }
    }

    private func turnIntoPanel(for id: Block.ID) -> some View {
        VStack(spacing: 0) {
            Text("Turn into").font(.system(size: 12)).foregroundStyle(Theme.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Theme.margin)
                .padding(.top, 8)
            AppMenuRow("Heading", systemImage: "textformat.size") { turnInto(.heading, id: id) }
            AppMenuRow("To-do", systemImage: "checkmark.square") { turnInto(.todo, id: id) }
            AppMenuRow("Toggle", systemImage: "chevron.right.circle", guideID: "editor.turn_into_toggle") { turnInto(.toggle, id: id) }
        }
        .background(Theme.pressed)
    }

    private func add(_ kind: BlockKind) {
        store.add(kind)
        menuOpen = false
    }

    private func turnInto(_ kind: BlockKind, id: Block.ID) {
        store.turnInto(kind, id: id)
        turnIntoBlock = nil
    }

    // MARK: - Blocks

    private func blockRow(_ block: Binding<Block>) -> some View {
        let kind = block.wrappedValue.kind
        return HStack(alignment: .firstTextBaseline, spacing: 8) {
            if kind == .todo {
                Button { block.isOn.wrappedValue.toggle() } label: {
                    Image(systemName: block.isOn.wrappedValue ? "checkmark.square.fill" : "square")
                        .foregroundStyle(Theme.icon)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(block.isOn.wrappedValue ? "Checked" : "Unchecked")
            } else if kind == .toggle {
                Button { block.isOn.wrappedValue.toggle() } label: {
                    Image(systemName: block.isOn.wrappedValue ? "chevron.down" : "chevron.right")
                        .foregroundStyle(Theme.icon)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(block.isOn.wrappedValue ? "Collapse" : "Expand")
            }
            TextField(placeholder(kind), text: block.text, axis: .vertical)
                .font(font(kind))
                .foregroundStyle(kind == .todo && block.isOn.wrappedValue ? Theme.secondary : Theme.ink)
                .strikethrough(kind == .todo && block.isOn.wrappedValue)
            if kind != .title {
                AppButton("", systemImage: "ellipsis", guideID: "editor.block_handle") {
                    menuOpen = false
                    let id = block.wrappedValue.id
                    turnIntoBlock = turnIntoBlock == id ? nil : id
                }
            }
        }
        .padding(.horizontal, Theme.margin)
        .padding(.vertical, kind == .title ? 8 : 4)
    }

    private func font(_ kind: BlockKind) -> Font {
        switch kind {
        case .title: return .system(size: 32, weight: .bold)
        case .heading: return .system(size: 22, weight: .semibold)
        default: return .system(size: 16)
        }
    }

    private func placeholder(_ kind: BlockKind) -> String {
        switch kind {
        case .title: return "Untitled"
        case .heading: return "Heading"
        case .todo: return "To-do"
        case .toggle: return "Toggle"
        case .text: return "Type something"
        }
    }
}
