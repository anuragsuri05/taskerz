import SwiftUI

struct BoardView: View {
    let tasks: [TaskItem]
    @Binding var selectedTasks: Set<UUID>
    let onInspect: (UUID) -> Void

    @AppStorage("sort") private var sort: TaskSort = .smart

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ForEach(TaskStatus.allCases) { status in
                BoardColumn(
                    status: status,
                    tasks: column(status),
                    selectedTasks: $selectedTasks,
                    onInspect: onInspect
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func column(_ status: TaskStatus) -> [TaskItem] {
        let items = tasks.filter { $0.status == status }
        if status == .done {
            return Array(items.sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }.prefix(60))
        }
        return sort.sorted(items)
    }
}

struct BoardColumn: View {
    let status: TaskStatus
    let tasks: [TaskItem]
    @Binding var selectedTasks: Set<UUID>
    let onInspect: (UUID) -> Void

    @EnvironmentObject private var store: TaskStore
    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: status.symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(status.tint)
                Text(status.title)
                    .font(.system(size: 13.5, weight: .semibold))
                Text("\(tasks.count)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(Color.primary.opacity(0.07)))
                Spacer()
            }
            .padding(.horizontal, 4)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(tasks) { task in
                        BoardCard(task: task, isSelected: selectedTasks.contains(task.id))
                            .onTapGesture(count: 2) { onInspect(task.id) }
                            .onTapGesture {
                                if NSEvent.modifierFlags.contains(.command) {
                                    selectedTasks.formSymmetricDifference([task.id])
                                } else {
                                    selectedTasks = [task.id]
                                }
                            }
                            .draggable(task.id.uuidString) {
                                BoardCard(task: task, isSelected: false).frame(width: 240)
                            }
                            .contextMenu {
                                TaskMenu(ids: selectedTasks.contains(task.id) ? selectedTasks : [task.id], onInspect: onInspect)
                            }
                    }
                    if tasks.isEmpty {
                        Text(isTargeted ? "Drop here" : "No tasks")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 28)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                    .foregroundStyle(.quaternary)
                            )
                    }
                }
                .padding(.bottom, 8)
                .animation(.snappy, value: tasks)
            }
            .scrollIndicators(.never)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isTargeted ? status.tint.opacity(0.12) : Color.primary.opacity(0.035))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(isTargeted ? status.tint.opacity(0.5) : .clear, lineWidth: 1.5)
                }
        }
        .dropDestination(for: String.self) { items, _ in
            let ids = items.compactMap(UUID.init(uuidString:))
            store.setStatus(status, for: ids)
            return !ids.isEmpty
        } isTargeted: { isTargeted = $0 }
        .animation(.snappy(duration: 0.2), value: isTargeted)
    }
}

struct BoardCard: View {
    let task: TaskItem
    let isSelected: Bool

    @EnvironmentObject private var store: TaskStore
    @EnvironmentObject private var calendar: CalendarService
    @State private var hovering = false

    var body: some View {
        let list = store.list(task.listID)
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .top, spacing: 8) {
                StatusButton(task: task, tint: list?.color.color ?? .accentColor)
                Text(task.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(task.isDone ? .secondary : .primary)
                    .strikethrough(task.isDone, color: .secondary)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if task.priority != .none {
                    Text(task.priority.marks)
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(.orange)
                }
            }
            if !task.notes.isEmpty {
                Text(task.notes)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(.leading, 28)
            }
            FlowLayout(spacing: 5) {
                if let label = task.dueLabel {
                    let state = task.dueState(now: calendar.now)
                    Pill(text: label, symbol: "calendar", tint: task.isDone ? .secondary : state.tint, filled: state == .overdue)
                }
                ForEach(task.tags, id: \.self) { Pill(text: "#\($0)", tint: .accentColor) }
                if let list {
                    HStack(spacing: 4) {
                        Circle().fill(list.color.color).frame(width: 7, height: 7)
                        Text(list.name).font(.system(size: 11))
                    }
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 2)
                }
            }
            .padding(.leading, 28)
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(hovering ? 0.12 : 0.06), radius: hovering ? 6 : 2, y: hovering ? 3 : 1)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(isSelected ? Color.accentColor : Color.primary.opacity(0.06), lineWidth: isSelected ? 2 : 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .onHover { hovering = $0 }
        .animation(.snappy(duration: 0.15), value: hovering)
    }
}
