import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: TaskStore
    @EnvironmentObject private var calendar: CalendarService

    @State private var selection: SidebarItem? = .today
    @State private var selectedTasks: Set<UUID> = []
    @State private var inspectedTaskID: UUID?
    @State private var showInspector = false
    @State private var searchText = ""
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    // Read here so the screen rebuilds when these options change.
    @AppStorage("showCompleted") private var showCompleted = false
    @AppStorage("sort") private var sort: TaskSort = .smart

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selection: $selection)
                .navigationSplitViewColumnWidth(min: 230, ideal: 260, max: 340)
        } detail: {
            detail
                .inspector(isPresented: $showInspector) {
                    inspector
                        .inspectorColumnWidth(min: 290, ideal: 320, max: 420)
                }
        }
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search tasks, tags & events")
        .onChange(of: selection) {
            selectedTasks = []
            searchText = ""
        }
        .onChange(of: selectedTasks) { _, new in
            if new.count == 1 { inspectedTaskID = new.first }
        }
        .onChange(of: store.tasks) {
            if let id = inspectedTaskID, store.task(id) == nil {
                inspectedTaskID = nil
                showInspector = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusQuickAdd)) { _ in
            if selection == .meetings || selection == .calendar { selection = .today }
        }
    }

    @ViewBuilder
    private var detail: some View {
        let current = selection ?? .today
        if !searchText.isEmpty {
            TaskScreen(
                config: ScreenBuilder.search(searchText, store: store, calendar: calendar),
                selectedTasks: $selectedTasks, onInspect: inspect
            )
        } else if current == .calendar {
            CalendarScreen(selectedTasks: $selectedTasks, onInspect: inspect)
        } else {
            TaskScreen(
                config: ScreenBuilder.config(for: current, store: store, calendar: calendar),
                selectedTasks: $selectedTasks, onInspect: inspect
            )
            .id(current)
        }
    }

    @ViewBuilder
    private var inspector: some View {
        if let id = inspectedTaskID, store.task(id) != nil {
            TaskInspector(taskID: id) {
                showInspector = false
            }
        } else {
            ContentUnavailableView("No Task Selected", systemImage: "checklist",
                                   description: Text("Select a task to see its details."))
        }
    }

    private func inspect(_ id: UUID) {
        selectedTasks = [id]
        inspectedTaskID = id
        withAnimation(.snappy) { showInspector = true }
    }
}
