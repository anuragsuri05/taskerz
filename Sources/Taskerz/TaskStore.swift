import SwiftUI
import AppKit

@MainActor
final class TaskStore: ObservableObject {
    @Published var tasks: [TaskItem] = [] { didSet { scheduleSave() } }
    @Published var lists: [TaskList] = [] { didSet { scheduleSave() } }

    private let fileURL: URL
    private var saveWork: DispatchWorkItem?
    private var isLoading = false

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Taskerz", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("data.json")
        load()

        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.saveNow() }
        }
    }

    // MARK: Persistence

    private func load() {
        isLoading = true
        defer { isLoading = false }

        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? Self.decoder.decode(AppData.self, from: data) {
            lists = decoded.lists
            tasks = decoded.tasks
        }
        if lists.isEmpty { seed() }
    }

    private func seed() {
        let personal = TaskList(name: "Personal", color: .blue, symbol: "person.fill")
        let work = TaskList(name: "Work", color: .orange, symbol: "briefcase.fill")
        lists = [personal, work]

        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        tasks = [
            TaskItem(title: "Welcome to Taskerz 👋", notes: "Click the circle to complete a task. Right-click for more options.",
                     dueDate: today, tags: ["welcome"], listID: personal.id),
            TaskItem(title: "Connect Google Calendar", notes: "Open Calendar in the sidebar and allow access.",
                     status: .inProgress, priority: .high, dueDate: today, listID: personal.id),
            TaskItem(title: "Try quick add: “Review deck tomorrow 3pm #work !!”",
                     dueDate: cal.date(byAdding: .day, value: 1, to: today), tags: ["tips"], listID: work.id),
        ]
    }

    private func scheduleSave() {
        guard !isLoading else { return }
        saveWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated { self?.saveNow() }
        }
        saveWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    func saveNow() {
        saveWork?.cancel()
        guard let data = try? Self.encoder.encode(AppData(tasks: tasks, lists: lists)) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: Tasks

    func task(_ id: UUID) -> TaskItem? { tasks.first { $0.id == id } }

    var defaultListID: UUID {
        if let first = lists.first { return first.id }
        let list = TaskList(name: "Personal", color: .blue, symbol: "person.fill")
        lists.append(list)
        return list.id
    }

    @discardableResult
    func addTask(_ draft: QuickAddResult, defaults: QuickAddDefaults) -> TaskItem {
        var tags = draft.tags
        if let tag = defaults.tag, !tags.contains(tag) { tags.append(tag) }
        let listID = defaults.listID.flatMap { id in lists.contains { $0.id == id } ? id : nil } ?? defaultListID
        let task = TaskItem(
            title: draft.title,
            status: defaults.status ?? .todo,
            priority: draft.priority,
            dueDate: draft.dueDate ?? defaults.dueDate,
            hasDueTime: draft.dueDate != nil && draft.hasTime,
            tags: tags,
            listID: listID
        )
        withAnimation(.snappy) { tasks.append(task) }
        return task
    }

    @discardableResult
    func addTask(from event: CalendarEvent) -> TaskItem {
        if let existing = tasks.first(where: { $0.linkedEventID == event.eventIdentifier && !$0.isDone }) {
            return existing
        }
        var notes = event.calendarTitle
        if let link = event.meeting?.url.absoluteString { notes += "\n\(link)" }
        let task = TaskItem(
            title: event.title, notes: notes, dueDate: event.start, hasDueTime: !event.isAllDay,
            tags: event.meeting != nil ? ["meeting"] : [], listID: defaultListID, linkedEventID: event.eventIdentifier
        )
        withAnimation(.snappy) { tasks.append(task) }
        return task
    }

    func update(_ task: TaskItem) {
        guard let i = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        var t = task
        let old = tasks[i]
        if t.status != old.status {
            t.completedAt = t.status == .done ? .now : nil
        }
        t.tags = Self.normalized(t.tags)
        if t != old { t.updatedAt = .now }
        tasks[i] = t
    }

    func mutate(_ id: UUID, _ change: (inout TaskItem) -> Void) {
        guard var t = task(id) else { return }
        change(&t)
        update(t)
    }

    func setStatus(_ status: TaskStatus, for ids: some Collection<UUID>) {
        withAnimation(.snappy) {
            for id in ids { mutate(id) { $0.status = status } }
        }
    }

    func toggleDone(_ id: UUID) {
        guard let t = task(id) else { return }
        setStatus(t.isDone ? .todo : .done, for: [id])
    }

    func delete(_ ids: some Collection<UUID>) {
        let set = Set(ids)
        withAnimation(.snappy) { tasks.removeAll { set.contains($0.id) } }
    }

    func clearCompleted(in ids: [UUID]) { delete(ids) }

    // MARK: Lists

    func list(_ id: UUID) -> TaskList? { lists.first { $0.id == id } }

    @discardableResult
    func saveList(_ list: TaskList) -> TaskList {
        if let i = lists.firstIndex(where: { $0.id == list.id }) { lists[i] = list } else { lists.append(list) }
        return list
    }

    func deleteList(_ id: UUID) {
        withAnimation(.snappy) {
            tasks.removeAll { $0.listID == id }
            lists.removeAll { $0.id == id }
        }
    }

    func moveLists(from source: IndexSet, to destination: Int) {
        lists.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: Tags

    var allTags: [String] {
        Array(Set(tasks.flatMap(\.tags))).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    nonisolated static func normalized(_ tags: [String]) -> [String] {
        var seen = Set<String>()
        return tags
            .map { $0.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "#")).lowercased() }
            .filter { !$0.isEmpty && seen.insert($0).inserted }
    }

    // MARK: Queries

    func tasks(for item: SidebarItem, now: Date = .now) -> [TaskItem] {
        let cal = Calendar.current
        switch item {
        case .today:
            return tasks.filter { t in
                guard let due = t.dueDate else { return false }
                if t.isDone { return t.completedAt.map(cal.isDateInToday) ?? false }
                return cal.startOfDay(for: due) <= cal.startOfDay(for: now) || t.dueState(now: now) == .overdue
            }
        case .upcoming: return tasks.filter { $0.dueDate != nil }
        case .all: return tasks
        case .inProgress: return tasks.filter { $0.status == .inProgress }
        case .overdue: return tasks.filter { $0.dueState(now: now) == .overdue }
        case .completed: return tasks.filter(\.isDone)
        case .list(let id): return tasks.filter { $0.listID == id }
        case .tag(let tag): return tasks.filter { $0.tags.contains(tag) }
        case .meetings, .calendar: return []
        }
    }

    func count(for item: SidebarItem, now: Date = .now) -> Int {
        let items = tasks(for: item, now: now)
        return item == .completed ? items.count : items.filter { !$0.isDone }.count
    }

    func tasks(dueOn day: Date) -> [TaskItem] {
        tasks.filter { t in t.dueDate.map { Calendar.current.isDate($0, inSameDayAs: day) } ?? false }
    }

    func search(_ text: String) -> [TaskItem] {
        let q = text.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        let tagQuery = q.hasPrefix("#") ? String(q.dropFirst()) : q
        return tasks.filter {
            $0.title.lowercased().contains(q) || $0.notes.lowercased().contains(q)
                || $0.tags.contains { $0.contains(tagQuery) }
        }
    }
}

// MARK: - Quick add

struct QuickAddDefaults {
    var listID: UUID?
    var dueDate: Date?
    var tag: String?
    var status: TaskStatus?
}

struct QuickAddResult {
    var title: String
    var dueDate: Date?
    var hasTime = false
    var tags: [String] = []
    var priority: Priority = .none
}

enum QuickAddParser {
    private static let timeRegex = try! NSRegularExpression(
        pattern: #"(\b\d{1,2}(:\d{2})?\s*(am|pm)\b|\b\d{1,2}:\d{2}\b|\bnoon\b|\bmidnight\b|\btonight\b)"#,
        options: .caseInsensitive
    )
    private static let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)

    static func parse(_ input: String) -> QuickAddResult {
        var words: [String] = []
        var result = QuickAddResult(title: "")

        for word in input.split(separator: " ", omittingEmptySubsequences: true).map(String.init) {
            if word.hasPrefix("#"), word.count > 1 {
                result.tags.append(String(word.dropFirst()))
            } else if word.allSatisfy({ $0 == "!" }), (1...3).contains(word.count) {
                result.priority = Priority(rawValue: word.count) ?? .none
            } else if word.hasPrefix("!"), let p = priority(named: String(word.dropFirst())) {
                result.priority = p
            } else {
                words.append(word)
            }
        }

        var text = words.joined(separator: " ")
        let ns = text as NSString
        if let match = detector.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)),
           let date = match.date {
            let phrase = ns.substring(with: match.range)
            result.hasTime = timeRegex.firstMatch(in: phrase, range: NSRange(location: 0, length: (phrase as NSString).length)) != nil
            result.dueDate = result.hasTime ? date : Calendar.current.startOfDay(for: date)
            text = ns.replacingCharacters(in: match.range, with: "")
        }

        var title = text.split(separator: " ").joined(separator: " ")
        for suffix in [" on", " at", " by", " due"] where title.lowercased().hasSuffix(suffix) {
            title = String(title.dropLast(suffix.count))
        }
        result.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.title.isEmpty { result.title = input.trimmingCharacters(in: .whitespaces) }
        result.tags = TaskStore.normalized(result.tags)
        return result
    }

    private static func priority(named name: String) -> Priority? {
        switch name.lowercased() {
        case "high", "h", "urgent": .high
        case "medium", "med", "m": .medium
        case "low", "l": .low
        default: nil
        }
    }
}
