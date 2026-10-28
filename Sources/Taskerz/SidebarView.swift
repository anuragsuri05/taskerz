import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var store: TaskStore
    @EnvironmentObject private var calendar: CalendarService
    @Binding var selection: SidebarItem?

    @State private var editingList: TaskList?
    @State private var listPendingDelete: TaskList?

    private let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        List(selection: $selection) {
            Section {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(SidebarItem.smartItems, id: \.self) { item in
                        SmartTile(item: item, count: store.count(for: item, now: calendar.now),
                                  isSelected: selection == item) {
                            selection = item
                        }
                    }
                }
                .padding(.vertical, 6)
                .listRowInsets(EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 2))
            }

            Section("Calendar") {
                SidebarRow(title: "Meetings", symbol: SidebarItem.meetings.symbol, tint: SidebarItem.meetings.tint,
                           count: calendar.hasAccess ? calendar.upcomingMeetings(days: 7).count : nil)
                    .tag(SidebarItem.meetings)
                SidebarRow(title: "Calendar", symbol: SidebarItem.calendar.symbol, tint: SidebarItem.calendar.tint,
                           count: calendar.hasAccess ? calendar.events(on: calendar.now).count : nil)
                    .tag(SidebarItem.calendar)
            }

            Section("My Lists") {
                ForEach(store.lists) { list in
                    SidebarRow(title: list.name, symbol: list.symbol, tint: list.color.color,
                               count: store.count(for: .list(list.id)))
                        .tag(SidebarItem.list(list.id))
                        .contextMenu {
                            Button("Edit List…") { editingList = list }
                            Divider()
                            Button("Delete List…", role: .destructive) { listPendingDelete = list }
                        }
                        .dropDestination(for: String.self) { items, _ in
                            for id in items.compactMap(UUID.init(uuidString:)) {
                                store.mutate(id) { $0.listID = list.id }
                            }
                            return true
                        }
                }
                .onMove { store.moveLists(from: $0, to: $1) }
            }

            if !store.allTags.isEmpty {
                Section("Tags") {
                    ForEach(store.allTags, id: \.self) { tag in
                        Label(tag, systemImage: "number")
                            .badge(store.count(for: .tag(tag)))
                            .tag(SidebarItem.tag(tag))
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button {
                    editingList = TaskList(name: "", color: ListColor.allCases.randomElement() ?? .blue)
                } label: {
                    Label("Add List", systemImage: "plus.circle")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .sheet(item: $editingList) { list in
            ListEditor(list: list) { saved in
                store.saveList(saved)
                selection = .list(saved.id)
            }
        }
        .confirmationDialog(
            "Delete “\(listPendingDelete?.name ?? "")”?",
            isPresented: Binding(get: { listPendingDelete != nil }, set: { if !$0 { listPendingDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Delete List and Its Tasks", role: .destructive) {
                if let list = listPendingDelete {
                    if selection == .list(list.id) { selection = .today }
                    store.deleteList(list.id)
                }
            }
        } message: {
            Text("This will delete all tasks in this list. This can’t be undone.")
        }
        .onReceive(NotificationCenter.default.publisher(for: .newList)) { _ in
            editingList = TaskList(name: "", color: ListColor.allCases.randomElement() ?? .blue)
        }
    }
}

// MARK: - Smart tile (Reminders style)

struct SmartTile: View {
    let item: SidebarItem
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .top) {
                    Image(systemName: item.symbol)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(isSelected ? item.tint : .white)
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(isSelected ? Color.white : item.tint))
                    Spacer(minLength: 0)
                    Text("\(count)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(isSelected ? .white : .primary)
                        .contentTransition(.numericText())
                }
                Text(item.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isSelected ? .white.opacity(0.95) : .secondary)
                    .lineLimit(1)
            }
            .padding(9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(item.tint.gradient) : AnyShapeStyle(Color.primary.opacity(hovering ? 0.09 : 0.055)))
            }
            .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.snappy(duration: 0.2), value: isSelected)
        .animation(.snappy, value: count)
    }
}

struct SidebarRow: View {
    let title: String
    let symbol: String
    let tint: Color
    let count: Int?

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: symbol)
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(tint.gradient))
            Text(title)
                .lineLimit(1)
            Spacer(minLength: 4)
            if let count, count > 0 {
                Text("\(count)")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 1)
    }
}

// MARK: - List editor sheet

struct ListEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State var list: TaskList
    let onSave: (TaskList) -> Void

    private let symbolColumns = Array(repeating: GridItem(.fixed(34), spacing: 10), count: 8)

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: list.symbol)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 72, height: 72)
                .background(Circle().fill(list.color.color.gradient))
                .shadow(color: list.color.color.opacity(0.35), radius: 10, y: 4)
                .padding(.top, 6)

            TextField("List Name", text: $list.name)
                .textFieldStyle(.plain)
                .font(.system(size: 20, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.primary.opacity(0.06)))
                .onSubmit(save)

            HStack(spacing: 10) {
                ForEach(ListColor.allCases) { c in
                    Circle()
                        .fill(c.color.gradient)
                        .frame(width: 24, height: 24)
                        .overlay {
                            if c == list.color {
                                Circle().strokeBorder(.background, lineWidth: 2.5).padding(1)
                                Circle().strokeBorder(c.color, lineWidth: 2).padding(-3)
                            }
                        }
                        .onTapGesture { list.color = c }
                }
            }

            LazyVGrid(columns: symbolColumns, spacing: 10) {
                ForEach(TaskList.symbols, id: \.self) { s in
                    Image(systemName: s)
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 34, height: 34)
                        .foregroundStyle(s == list.symbol ? .white : .primary)
                        .background(Circle().fill(s == list.symbol ? AnyShapeStyle(list.color.color) : AnyShapeStyle(Color.primary.opacity(0.06))))
                        .onTapGesture { list.symbol = s }
                }
            }

            HStack {
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Done", action: save)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(list.name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 400)
    }

    private func save() {
        list.name = list.name.trimmingCharacters(in: .whitespaces)
        guard !list.name.isEmpty else { return }
        onSave(list)
        dismiss()
    }
}
