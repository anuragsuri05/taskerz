import SwiftUI

struct ScreenSection: Identifiable {
    let id: String
    var title: String?
    var tint: Color? = nil
    var events: [CalendarEvent] = []
    var tasks: [TaskItem] = []

    var isEmpty: Bool { events.isEmpty && tasks.isEmpty }
}

struct ScreenConfig {
    var title: String
    var subtitle: String?
    var tint: Color
    var sections: [ScreenSection]
    /// Tasks for the Kanban board. `nil` means this screen has no board mode.
    var boardTasks: [TaskItem]?
    /// Defaults for new tasks typed into the quick-add bar. `nil` hides the bar.
    var quickAdd: QuickAddDefaults?
    var showListBadge = true
    var needsCalendar = false
    var showsNextMeeting = false
    var emptyTitle = "All Done"
    var emptySymbol = "checkmark.circle"
    var emptyMessage = "Nothing here right now."

    var headerCount: Int {
        let tasks = boardTasks ?? sections.flatMap(\.tasks)
        let open = tasks.filter { !$0.isDone }.count
        return boardTasks == nil && open == 0 ? sections.reduce(0) { $0 + $1.events.count } : open
    }

    var isEmpty: Bool { sections.allSatisfy(\.isEmpty) }
}

enum ViewMode: String, CaseIterable {
    case list, board
}

@MainActor
enum ScreenBuilder {
    private static var showCompleted: Bool { UserDefaults.standard.bool(forKey: "showCompleted") }
    private static var sort: TaskSort {
        TaskSort(rawValue: UserDefaults.standard.string(forKey: "sort") ?? "") ?? .smart
    }

    static func dayTitle(_ day: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(day) { return "Today" }
        if cal.isDateInTomorrow(day) { return "Tomorrow" }
        if cal.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    static func config(for item: SidebarItem, store: TaskStore, calendar: CalendarService) -> ScreenConfig {
        let now = calendar.now
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        let sort = sort
        let showCompleted = showCompleted
        let visible: ([TaskItem]) -> [TaskItem] = { sort.sorted(showCompleted ? $0 : $0.filter { !$0.isDone }) }

        switch item {
        case .today:
            let tasks = store.tasks(for: .today, now: now)
            let overdue = tasks.filter { $0.dueState(now: now) == .overdue }
            let dueToday = tasks.filter { !$0.isDone && $0.dueState(now: now) != .overdue }
            var sections = [
                ScreenSection(id: "schedule", title: "Schedule", tint: .red, events: calendar.events(on: now)),
                ScreenSection(id: "overdue", title: "Overdue", tint: .red, tasks: sort.sorted(overdue)),
                ScreenSection(id: "today", title: "Today", tasks: sort.sorted(dueToday)),
            ]
            if showCompleted {
                sections.append(ScreenSection(id: "done", title: "Completed", tasks: tasks.filter(\.isDone)))
            }
            return ScreenConfig(
                title: "Today", subtitle: now.formatted(.dateTime.weekday(.wide).month(.wide).day()),
                tint: item.tint, sections: sections, boardTasks: tasks,
                quickAdd: QuickAddDefaults(dueDate: today), needsCalendar: true, showsNextMeeting: true,
                emptyTitle: "Your day is clear", emptySymbol: "sun.max",
                emptyMessage: "No tasks or events today. Add one below."
            )

        case .upcoming:
            let tasks = store.tasks(for: .upcoming, now: now)
            var sections: [ScreenSection] = []
            let overdue = tasks.filter { $0.dueState(now: now) == .overdue }
            if !overdue.isEmpty {
                sections.append(ScreenSection(id: "overdue", title: "Overdue", tint: .red, tasks: sort.sorted(overdue)))
            }
            for offset in 0..<14 {
                let day = cal.date(byAdding: .day, value: offset, to: today)!
                let dayTasks = visible(tasks.filter { t in
                    t.dueState(now: now) != .overdue && t.dueDate.map { cal.isDate($0, inSameDayAs: day) } == true
                })
                let section = ScreenSection(id: "d\(offset)", title: dayTitle(day), tint: offset == 0 ? .blue : nil,
                                            events: calendar.events(on: day), tasks: dayTasks)
                if !section.isEmpty { sections.append(section) }
            }
            let horizon = cal.date(byAdding: .day, value: 14, to: today)!
            let later = visible(tasks.filter { ($0.dueDate ?? .distantPast) >= horizon })
            if !later.isEmpty { sections.append(ScreenSection(id: "later", title: "Later", tasks: later)) }
            return ScreenConfig(
                title: "Upcoming", subtitle: "Next two weeks", tint: item.tint, sections: sections,
                boardTasks: tasks.filter { !$0.isDone || showCompleted || $0.dueDate.map { $0 >= today } == true },
                quickAdd: QuickAddDefaults(dueDate: today), needsCalendar: true,
                emptyTitle: "Nothing scheduled", emptySymbol: "calendar",
                emptyMessage: "Tasks with due dates and calendar events appear here."
            )

        case .all:
            let tasks = store.tasks
            let sections = store.lists.map { list in
                ScreenSection(id: list.id.uuidString, title: list.name, tint: list.color.color,
                              tasks: visible(tasks.filter { $0.listID == list.id }))
            }.filter { !$0.isEmpty }
            return ScreenConfig(title: "All", tint: item.tint, sections: sections, boardTasks: tasks,
                                quickAdd: QuickAddDefaults(), showListBadge: false,
                                emptyTitle: "No Tasks", emptySymbol: "tray", emptyMessage: "Add your first task below.")

        case .inProgress:
            let tasks = store.tasks(for: .inProgress)
            return ScreenConfig(
                title: "Working On", subtitle: "Tasks you’ve started", tint: item.tint,
                sections: [ScreenSection(id: "wip", tasks: sort.sorted(tasks))],
                boardTasks: store.tasks.filter { !$0.isDone || $0.completedAt.map(cal.isDateInToday) == true },
                quickAdd: QuickAddDefaults(status: .inProgress),
                emptyTitle: "Nothing in progress", emptySymbol: "timer",
                emptyMessage: "Right-click a task and choose Status › Working On."
            )

        case .overdue:
            let tasks = store.tasks(for: .overdue, now: now)
            return ScreenConfig(
                title: "Overdue", tint: item.tint, sections: [ScreenSection(id: "overdue", tasks: sort.sorted(tasks))],
                boardTasks: tasks, quickAdd: nil,
                emptyTitle: "You’re all caught up", emptySymbol: "checkmark.seal", emptyMessage: "No overdue tasks."
            )

        case .completed:
            let tasks = store.tasks(for: .completed).sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
            let grouped = Dictionary(grouping: tasks) { cal.startOfDay(for: $0.completedAt ?? $0.updatedAt) }
            let sections = grouped.keys.sorted(by: >).map { day in
                ScreenSection(id: "\(day.timeIntervalSince1970)", title: dayTitle(day), tasks: grouped[day] ?? [])
            }
            return ScreenConfig(title: "Completed", tint: item.tint, sections: sections, boardTasks: nil, quickAdd: nil,
                                emptyTitle: "No Completed Tasks", emptySymbol: "checkmark.circle",
                                emptyMessage: "Completed tasks show up here.")

        case .meetings:
            let meetings = calendar.upcomingMeetings()
            let grouped = Dictionary(grouping: meetings) { cal.startOfDay(for: $0.start) }
            let sections = grouped.keys.sorted().map { day in
                ScreenSection(id: "\(day.timeIntervalSince1970)", title: dayTitle(day),
                              tint: cal.isDateInToday(day) ? .green : nil, events: grouped[day] ?? [])
            }
            return ScreenConfig(
                title: "Meetings", subtitle: "Google Meet, Zoom & Teams from your calendar", tint: item.tint,
                sections: sections, boardTasks: nil, quickAdd: nil, needsCalendar: true, showsNextMeeting: true,
                emptyTitle: "No upcoming meetings", emptySymbol: "video",
                emptyMessage: "Events with a Google Meet, Zoom or Teams link appear here automatically."
            )

        case .list(let id):
            let list = store.list(id)
            let tasks = store.tasks(for: item)
            return ScreenConfig(
                title: list?.name ?? "List", tint: list?.color.color ?? .blue,
                sections: statusSections(tasks, sort: sort, showCompleted: showCompleted),
                boardTasks: tasks, quickAdd: QuickAddDefaults(listID: id), showListBadge: false,
                emptyTitle: "No Tasks", emptySymbol: list?.symbol ?? "list.bullet", emptyMessage: "Add a task below."
            )

        case .tag(let tag):
            let tasks = store.tasks(for: item)
            return ScreenConfig(
                title: "#\(tag)", tint: .accentColor,
                sections: statusSections(tasks, sort: sort, showCompleted: showCompleted),
                boardTasks: tasks, quickAdd: QuickAddDefaults(tag: tag),
                emptyTitle: "No Tasks", emptySymbol: "number", emptyMessage: "Nothing tagged #\(tag)."
            )

        case .calendar:
            return ScreenConfig(title: "Calendar", tint: .red, sections: [])
        }
    }

    static func statusSections(_ tasks: [TaskItem], sort: TaskSort, showCompleted: Bool) -> [ScreenSection] {
        var statuses: [TaskStatus] = [.inProgress, .todo]
        if showCompleted { statuses.append(.done) }
        return statuses.map { s in
            ScreenSection(id: s.rawValue, title: s.title, tint: s == .inProgress ? .orange : nil,
                          tasks: sort.sorted(tasks.filter { $0.status == s }))
        }
    }

    static func search(_ text: String, store: TaskStore, calendar: CalendarService) -> ScreenConfig {
        ScreenConfig(
            title: "Results", subtitle: "for “\(text)”", tint: .secondary,
            sections: [
                ScreenSection(id: "tasks", title: "Tasks", tasks: TaskSort.smart.sorted(store.search(text))),
                ScreenSection(id: "events", title: "Events", events: calendar.search(text)),
            ],
            boardTasks: nil, quickAdd: nil,
            emptyTitle: "No Results", emptySymbol: "magnifyingglass", emptyMessage: "Try a different search."
        )
    }
}
