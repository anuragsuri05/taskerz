import SwiftUI

// MARK: - Status

enum TaskStatus: String, Codable, CaseIterable, Identifiable {
    case todo, inProgress, done

    var id: String { rawValue }

    var title: String {
        switch self {
        case .todo: "To Do"
        case .inProgress: "Working On"
        case .done: "Completed"
        }
    }

    var symbol: String {
        switch self {
        case .todo: "circle"
        case .inProgress: "circle.lefthalf.filled"
        case .done: "checkmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .todo: .gray
        case .inProgress: .orange
        case .done: .green
        }
    }
}

// MARK: - Priority

enum Priority: Int, Codable, CaseIterable, Identifiable, Comparable {
    case none = 0, low, medium, high

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .none: "None"
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }
    }

    var marks: String { String(repeating: "!", count: rawValue) }

    static func < (lhs: Priority, rhs: Priority) -> Bool { lhs.rawValue < rhs.rawValue }
}

// MARK: - Due state

enum DueState {
    case none, overdue, today, tomorrow, soon, later

    var tint: Color {
        switch self {
        case .overdue: .red
        case .today: .blue
        case .tomorrow: .indigo
        default: .secondary
        }
    }
}

// MARK: - Task

struct TaskItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var notes: String = ""
    var status: TaskStatus = .todo
    var priority: Priority = .none
    var dueDate: Date?
    var hasDueTime = false
    var tags: [String] = []
    var listID: UUID
    var createdAt = Date()
    var updatedAt = Date()
    var completedAt: Date?
    var linkedEventID: String?

    var isDone: Bool { status == .done }

    func dueState(now: Date = .now) -> DueState {
        guard let due = dueDate, !isDone else { return .none }
        let cal = Calendar.current
        if hasDueTime ? due < now : cal.startOfDay(for: due) < cal.startOfDay(for: now) { return .overdue }
        if cal.isDateInToday(due) { return .today }
        if cal.isDateInTomorrow(due) { return .tomorrow }
        if let week = cal.date(byAdding: .day, value: 7, to: now), due < week { return .soon }
        return .later
    }

    var dueLabel: String? {
        guard let due = dueDate else { return nil }
        let cal = Calendar.current
        let day: String
        if cal.isDateInToday(due) { day = "Today" }
        else if cal.isDateInTomorrow(due) { day = "Tomorrow" }
        else if cal.isDateInYesterday(due) { day = "Yesterday" }
        else if let diff = cal.dateComponents([.day], from: cal.startOfDay(for: .now), to: cal.startOfDay(for: due)).day,
                diff > 1, diff < 7 {
            day = due.formatted(.dateTime.weekday(.wide))
        } else if cal.isDate(due, equalTo: .now, toGranularity: .year) {
            day = due.formatted(.dateTime.month(.abbreviated).day())
        } else {
            day = due.formatted(.dateTime.month(.abbreviated).day().year())
        }
        return hasDueTime ? "\(day), \(due.formatted(date: .omitted, time: .shortened))" : day
    }
}

// MARK: - Lists

enum ListColor: String, Codable, CaseIterable, Identifiable {
    case red, orange, yellow, green, mint, teal, cyan, blue, indigo, purple, pink, brown, gray

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .mint: .mint
        case .teal: .teal
        case .cyan: .cyan
        case .blue: .blue
        case .indigo: .indigo
        case .purple: .purple
        case .pink: .pink
        case .brown: .brown
        case .gray: .gray
        }
    }
}

struct TaskList: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var color: ListColor = .blue
    var symbol: String = "list.bullet"

    static let symbols = [
        "list.bullet", "briefcase.fill", "house.fill", "person.fill", "cart.fill", "book.fill",
        "graduationcap.fill", "heart.fill", "star.fill", "flag.fill", "bolt.fill", "leaf.fill",
        "airplane", "car.fill", "dumbbell.fill", "fork.knife", "gift.fill", "laptopcomputer",
        "hammer.fill", "paintbrush.fill", "music.note", "camera.fill", "creditcard.fill", "lightbulb.fill"
    ]
}

struct AppData: Codable {
    var tasks: [TaskItem]
    var lists: [TaskList]
}

// MARK: - Sorting

enum TaskSort: String, CaseIterable, Identifiable {
    case smart, dueDate, priority, title, created

    var id: String { rawValue }

    var title: String {
        switch self {
        case .smart: "Smart"
        case .dueDate: "Due Date"
        case .priority: "Priority"
        case .title: "Title"
        case .created: "Date Created"
        }
    }

    func sorted(_ tasks: [TaskItem]) -> [TaskItem] {
        tasks.sorted { a, b in
            switch self {
            case .smart:
                let rank: (TaskStatus) -> Int = { $0 == .inProgress ? 0 : $0 == .todo ? 1 : 2 }
                if rank(a.status) != rank(b.status) { return rank(a.status) < rank(b.status) }
                if a.dueDate != b.dueDate { return (a.dueDate ?? .distantFuture) < (b.dueDate ?? .distantFuture) }
                if a.priority != b.priority { return a.priority > b.priority }
                return a.createdAt < b.createdAt
            case .dueDate:
                return (a.dueDate ?? .distantFuture) < (b.dueDate ?? .distantFuture)
            case .priority:
                return a.priority == b.priority ? a.createdAt < b.createdAt : a.priority > b.priority
            case .title:
                return a.title.localizedStandardCompare(b.title) == .orderedAscending
            case .created:
                return a.createdAt > b.createdAt
            }
        }
    }
}

// MARK: - Sidebar navigation

enum SidebarItem: Hashable {
    case today, upcoming, all, inProgress, overdue, completed
    case meetings, calendar
    case list(UUID)
    case tag(String)

    static let smartItems: [SidebarItem] = [.today, .upcoming, .all, .inProgress, .overdue, .completed]

    var title: String {
        switch self {
        case .today: "Today"
        case .upcoming: "Upcoming"
        case .all: "All"
        case .inProgress: "Working On"
        case .overdue: "Overdue"
        case .completed: "Completed"
        case .meetings: "Meetings"
        case .calendar: "Calendar"
        case .list: "List"
        case .tag(let t): "#\(t)"
        }
    }

    var symbol: String {
        switch self {
        case .today: "sun.max.fill"
        case .upcoming: "calendar"
        case .all: "tray.fill"
        case .inProgress: "timer"
        case .overdue: "exclamationmark.triangle.fill"
        case .completed: "checkmark"
        case .meetings: "video.fill"
        case .calendar: "calendar.day.timeline.left"
        case .list: "list.bullet"
        case .tag: "number"
        }
    }

    var tint: Color {
        switch self {
        case .today: .blue
        case .upcoming: .red
        case .all: Color(nsColor: .systemGray)
        case .inProgress: .orange
        case .overdue: .pink
        case .completed: .gray
        case .meetings: .green
        case .calendar: .red
        case .list: .blue
        case .tag: .accentColor
        }
    }
}
