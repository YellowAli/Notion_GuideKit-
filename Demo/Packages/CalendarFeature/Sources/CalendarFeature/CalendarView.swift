import SwiftUI
import DesignSystem
import GuideKit

public struct CalendarView: View {
    @State private var store = EventStore()
    @State private var showForm = false
    @State private var title = EventStore.defaultTitle

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            header
            Hairline()
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(store.events) { event in
                        Text(event.title)
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, Theme.margin)
                .padding(.vertical, 16)
            }
            if showForm { form }
        }
        .background(Theme.page)
        .guideFact("calendar.event.count", value: store.events.count)
    }

    private var header: some View {
        HStack {
            Text("Calendar").font(.system(size: 14)).foregroundStyle(Theme.secondary)
            Spacer()
            AppButton("New event", systemImage: "plus", guideID: "calendar.new_event") {
                title = EventStore.defaultTitle
                showForm = true
            }
        }
        .padding(.horizontal, Theme.margin - 8)
        .frame(minHeight: 44)
    }

    private var form: some View {
        VStack(spacing: 0) {
            Hairline()
            HStack {
                TextField("Event title", text: $title)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.ink)
                AppButton("Save", guideID: "calendar.save") {
                    store.addEvent(title: title.isEmpty ? EventStore.defaultTitle : title)
                    showForm = false
                }
            }
            .padding(.horizontal, Theme.margin - 8)
            .frame(minHeight: 44)
        }
    }
}
