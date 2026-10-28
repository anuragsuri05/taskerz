import SwiftUI

struct CalendarScreen: View {
    @Binding var selectedTasks: Set<UUID>
    let onInspect: (UUID) -> Void

    @EnvironmentObject private var store: TaskStore
    @EnvironmentObject private var calendar: CalendarService
    @State private var date = Date()

    var body: some View {
        HStack(spacing: 0) {
            sidePanel
                .frame(width: 280)
            Divider()
            agenda
        }
        .background(Color(nsColor: .textBackgroundColor))
        .navigationTitle("Calendar")
        .hideToolbarTitle()
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                ControlGroup {
                    Button { shift(-1) } label: { Label("Previous Day", systemImage: "chevron.left") }
                    Button("Today") { withAnimation(.snappy) { date = .now } }
                    Button { shift(1) } label: { Label("Next Day", systemImage: "chevron.right") }
                }
                if calendar.hasAccess {
                    Button { calendar.syncNow() } label: {
                        Label("Sync Calendar", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .help("Sync now (⌘R)")
                }
            }
        }
    }

    private var sidePanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                MonthGrid(selection: $date)

                Divider()

                if calendar.hasAccess {
                    CalendarToggleList()
                    if let refreshed = calendar.lastRefreshed {
                        Text("Synced \(refreshed.formatted(date: .omitted, time: .shortened))")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(16)
        }
    }

    private var agenda: some View {
        let events = calendar.events(on: date)
        let tasks = TaskSort.smart.sorted(store.tasks(dueOn: date))
        return List(selection: $selectedTasks) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(ScreenBuilder.dayTitle(date))
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(Calendar.current.isDateInToday(date) ? Color.red : Color.primary)
                    Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.top, 14)
            .listRowSeparator(.hidden)

            if !calendar.hasAccess {
                CalendarConnectCard()
                    .listRowSeparator(.hidden)
                    .padding(.vertical, 6)
            }

            if !events.isEmpty {
                Section {
                    ForEach(events) { EventRow(event: $0) }
                } header: {
                    SectionHeader(title: "Events", tint: .red, count: events.count)
                }
            }

            if !tasks.isEmpty {
                Section {
                    ForEach(tasks) { task in
                        TaskRow(task: task) { onInspect(task.id) }
                            .tag(task.id)
                    }
                } header: {
                    SectionHeader(title: "Tasks Due", count: tasks.filter { !$0.isDone }.count)
                }
            }
        }
        .listStyle(.inset)
        .scrollContentBackground(.hidden)
        .contextMenu(forSelectionType: UUID.self) { ids in
            if !ids.isEmpty { TaskMenu(ids: ids, onInspect: onInspect) }
        } primaryAction: { ids in
            if let id = ids.first { onInspect(id) }
        }
        .onDeleteCommand { store.delete(selectedTasks) }
        .overlay {
            if events.isEmpty && tasks.isEmpty && calendar.hasAccess {
                ContentUnavailableView("Nothing Scheduled", systemImage: "calendar",
                                       description: Text("No events or tasks on this day."))
            }
        }
    }

    private func shift(_ days: Int) {
        withAnimation(.snappy) {
            date = Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
        }
    }
}

struct CalendarToggleList: View {
    @EnvironmentObject private var calendar: CalendarService

    var body: some View {
        let accounts = Dictionary(grouping: calendar.calendars, by: \.account)
        let ordered = calendar.calendars.map(\.account).reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }

        VStack(alignment: .leading, spacing: 14) {
            if !calendar.hasGoogleAccount {
                Button {
                    CalendarService.openInternetAccounts()
                } label: {
                    Label("Add Google Account…", systemImage: "plus.circle.fill")
                        .font(.system(size: 12.5, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
            }

            ForEach(ordered, id: \.self) { account in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 5) {
                        if accounts[account]?.first?.isGoogle == true {
                            Image(systemName: "g.circle.fill").foregroundStyle(.blue)
                        }
                        Text(account)
                            .lineLimit(1)
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)

                    ForEach(accounts[account] ?? []) { cal in
                        Toggle(isOn: Binding(
                            get: { !calendar.hiddenCalendarIDs.contains(cal.id) },
                            set: { on in
                                if on { calendar.hiddenCalendarIDs.remove(cal.id) } else { calendar.hiddenCalendarIDs.insert(cal.id) }
                            }
                        )) {
                            Text(cal.title)
                                .font(.system(size: 12.5))
                                .lineLimit(1)
                        }
                        .toggleStyle(.checkbox)
                        .tint(cal.color)
                    }
                }
            }
        }
    }
}
