import SwiftUI

struct TaskScreen: View {
    let config: ScreenConfig
    @Binding var selectedTasks: Set<UUID>
    let onInspect: (UUID) -> Void

    @EnvironmentObject private var store: TaskStore
    @EnvironmentObject private var calendar: CalendarService
    @AppStorage("viewMode") private var viewMode: ViewMode = .list
    @AppStorage("showCompleted") private var showCompleted = false
    @AppStorage("sort") private var sort: TaskSort = .smart

    private var showsBoard: Bool { viewMode == .board && config.boardTasks != nil }

    var body: some View {
        VStack(spacing: 0) {
            if showsBoard {
                ScreenHeader(config: config)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 14)
                BoardView(tasks: config.boardTasks ?? [], selectedTasks: $selectedTasks, onInspect: onInspect)
            } else {
                listContent
            }
            if let defaults = config.quickAdd {
                QuickAddBar(defaults: defaults, tint: config.tint) { task in
                    selectedTasks = [task.id]
                }
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
        .navigationTitle(config.title)
        .hideToolbarTitle()
        .toolbar { toolbar }
    }

    // MARK: List

    private var listContent: some View {
        List(selection: $selectedTasks) {
            ScreenHeader(config: config)
                .listRowSeparator(.hidden)
                .padding(.bottom, 4)

            if config.needsCalendar && !calendar.hasAccess {
                CalendarConnectCard()
                    .listRowSeparator(.hidden)
                    .padding(.vertical, 6)
            }

            if config.showsNextMeeting, let meeting = calendar.nextMeeting {
                NextMeetingCard(event: meeting)
                    .listRowSeparator(.hidden)
                    .padding(.vertical, 6)
            }

            ForEach(config.sections.filter { !$0.isEmpty }) { section in
                Section {
                    ForEach(section.events) { event in
                        EventRow(event: event)
                    }
                    ForEach(section.tasks) { task in
                        TaskRow(task: task, showList: config.showListBadge) { onInspect(task.id) }
                            .tag(task.id)
                            .draggable(task.id.uuidString)
                    }
                } header: {
                    if let title = section.title {
                        SectionHeader(title: title, tint: section.tint,
                                      count: section.tasks.filter { !$0.isDone }.count + section.events.count)
                    }
                }
            }
        }
        .listStyle(.inset)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, 34)
        .contextMenu(forSelectionType: UUID.self) { ids in
            if !ids.isEmpty {
                TaskMenu(ids: ids, onInspect: onInspect)
            }
        } primaryAction: { ids in
            if let id = ids.first { onInspect(id) }
        }
        .onDeleteCommand { store.delete(selectedTasks) }
        .overlay {
            if config.isEmpty && !(config.needsCalendar && !calendar.hasAccess)
                && !(config.showsNextMeeting && calendar.nextMeeting != nil) {
                ContentUnavailableView(config.emptyTitle, systemImage: config.emptySymbol,
                                       description: Text(config.emptyMessage))
                    .padding(.top, 60)
            }
        }
        .animation(.snappy, value: config.sections.map(\.tasks))
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            if config.boardTasks != nil {
                Picker("View", selection: $viewMode) {
                    Label("List", systemImage: "list.bullet").tag(ViewMode.list)
                    Label("Board", systemImage: "rectangle.split.3x1").tag(ViewMode.board)
                }
                .pickerStyle(.segmented)
                .help("Switch between list and board")
            }

            Menu {
                Picker("Sort By", selection: $sort) {
                    ForEach(TaskSort.allCases) { Text($0.title).tag($0) }
                }
                Toggle("Show Completed", isOn: $showCompleted)
                let done = (config.boardTasks ?? config.sections.flatMap(\.tasks)).filter(\.isDone).map(\.id)
                if !done.isEmpty {
                    Divider()
                    Button("Clear \(done.count) Completed", role: .destructive) { store.delete(done) }
                }
            } label: {
                Label("View Options", systemImage: "line.3.horizontal.decrease.circle")
            }
            .help("Sort and filter")

            if calendar.hasAccess {
                Button { calendar.syncNow() } label: {
                    Label("Sync Calendar", systemImage: "arrow.triangle.2.circlepath")
                }
                .help("Sync Google Calendar now (⌘R)")
            }

            if config.quickAdd != nil {
                Button {
                    NotificationCenter.default.post(name: .focusQuickAdd, object: nil)
                } label: {
                    Label("New Task", systemImage: "plus")
                }
                .help("New task (⌘N)")
            }

            Button {
                if let id = selectedTasks.first { onInspect(id) }
            } label: {
                Label("Show Info", systemImage: "info.circle")
            }
            .disabled(selectedTasks.count != 1)
            .keyboardShortcut("i")
            .help("Show task details (⌘I)")
        }
    }
}

// MARK: - Header

struct ScreenHeader: View {
    let config: ScreenConfig

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(config.title)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(config.tint)
                if let subtitle = config.subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("\(config.headerCount)")
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(config.tint)
                .contentTransition(.numericText())
                .animation(.snappy, value: config.headerCount)
        }
        .padding(.top, 14)
    }
}

struct SectionHeader: View {
    let title: String
    var tint: Color?
    var count: Int

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(tint ?? .primary)
            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.top, 10)
        .padding(.bottom, 2)
    }
}

// MARK: - Quick add

struct QuickAddBar: View {
    let defaults: QuickAddDefaults
    let tint: Color
    let onAdd: (TaskItem) -> Void

    @EnvironmentObject private var store: TaskStore
    @State private var text = ""
    @FocusState private var focused: Bool

    private var parsed: QuickAddResult? { text.trimmingCharacters(in: .whitespaces).isEmpty ? nil : QuickAddParser.parse(text) }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 19))
                .foregroundStyle(tint == .secondary ? Color.accentColor : tint)
                .symbolRenderingMode(.hierarchical)
            TextField("New Task — try “Call Alex tomorrow 4pm #work !!”", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13.5))
                .focused($focused)
                .onSubmit(add)
                .onExitCommand { text = ""; focused = false }

            if let p = parsed {
                HStack(spacing: 6) {
                    if let due = p.dueDate {
                        Pill(text: TaskItem(title: "", dueDate: due, hasDueTime: p.hasTime, listID: UUID()).dueLabel ?? "",
                             symbol: "calendar", tint: .blue)
                    }
                    if p.priority != .none { Pill(text: p.priority.title, symbol: "exclamationmark", tint: .orange) }
                    ForEach(p.tags, id: \.self) { Pill(text: "#\($0)", tint: .accentColor) }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
        .animation(.snappy(duration: 0.2), value: parsed?.dueDate)
        .onReceive(NotificationCenter.default.publisher(for: .focusQuickAdd)) { _ in
            focused = true
        }
    }

    private func add() {
        guard let p = parsed else { return }
        let task = store.addTask(p, defaults: defaults)
        text = ""
        onAdd(task)
        focused = true
    }
}

// MARK: - macOS 15 title hiding

private struct HideToolbarTitle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 15.0, *) {
            content.toolbar(removing: .title)
        } else {
            content
        }
    }
}

extension View {
    func hideToolbarTitle() -> some View { modifier(HideToolbarTitle()) }
}
