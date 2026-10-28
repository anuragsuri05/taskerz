import SwiftUI
import EventKit
import AppKit

struct MeetingLink: Hashable {
    enum Kind { case googleMeet, zoom, teams, webex, other }

    let url: URL
    let kind: Kind

    var title: String {
        switch kind {
        case .googleMeet: "Google Meet"
        case .zoom: "Zoom"
        case .teams: "Teams"
        case .webex: "Webex"
        case .other: "Meeting"
        }
    }

    var tint: Color {
        switch kind {
        case .googleMeet: Color(red: 0.0, green: 0.54, blue: 0.42)
        case .zoom: .blue
        case .teams: .indigo
        case .webex: .teal
        case .other: .accentColor
        }
    }

    private static let patterns: [(Kind, NSRegularExpression)] = ([
        (Kind.googleMeet, #"https?://meet\.google\.com/[a-z0-9\-]+(\?[^\s<>"']*)?"#),
        (.zoom, #"https?://([\w-]+\.)*zoom\.us/(j|my|w|s)/[^\s<>"']+"#),
        (.teams, #"https?://teams\.(microsoft|live)\.com/(l/meetup-join|meet)/[^\s<>"']+"#),
        (.webex, #"https?://([\w-]+\.)*webex\.com/[^\s<>"']+"#),
    ] as [(Kind, String)]).map { ($0.0, try! NSRegularExpression(pattern: $0.1, options: .caseInsensitive)) }

    static func find(in texts: [String?]) -> MeetingLink? {
        let haystack = texts.compactMap { $0 }.joined(separator: "\n")
        let range = NSRange(location: 0, length: (haystack as NSString).length)
        for (kind, regex) in patterns {
            if let m = regex.firstMatch(in: haystack, range: range),
               let url = URL(string: (haystack as NSString).substring(with: m.range)) {
                return MeetingLink(url: url, kind: kind)
            }
        }
        return nil
    }
}

struct CalendarEvent: Identifiable, Hashable {
    let id: String
    let eventIdentifier: String
    let title: String
    let start: Date
    let end: Date
    let isAllDay: Bool
    let location: String?
    let notes: String?
    let calendarID: String
    let calendarTitle: String
    let accountTitle: String
    let color: Color
    let meeting: MeetingLink?
    let attendeeCount: Int

    func isLive(at now: Date) -> Bool { start <= now && now < end && !isAllDay }

    var timeLabel: String {
        if isAllDay { return "All day" }
        let s = start.formatted(date: .omitted, time: .shortened)
        let e = end.formatted(date: .omitted, time: .shortened)
        return "\(s) – \(e)"
    }

    func relativeLabel(now: Date) -> String {
        if isLive(at: now) {
            let mins = Int(end.timeIntervalSince(now) / 60)
            return mins <= 1 ? "Ending now" : "Ends in \(mins) min"
        }
        let mins = Int(ceil(start.timeIntervalSince(now) / 60))
        if mins <= 0 { return "Started" }
        if mins < 60 { return "In \(mins) min" }
        if Calendar.current.isDateInToday(start) {
            let h = mins / 60, m = mins % 60
            return m == 0 ? "In \(h) hr" : "In \(h) hr \(m) min"
        }
        return start.formatted(.dateTime.weekday(.abbreviated).hour().minute())
    }
}

struct CalendarInfo: Identifiable, Hashable {
    let id: String
    let title: String
    let account: String
    let color: Color
    let isGoogle: Bool
}

@MainActor
final class CalendarService: ObservableObject {
    let store = EKEventStore()

    @Published private(set) var status: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)
    @Published private(set) var events: [CalendarEvent] = []
    @Published private(set) var calendars: [CalendarInfo] = []
    @Published private(set) var lastRefreshed: Date?
    @Published private(set) var now = Date()
    @Published var hiddenCalendarIDs: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(hiddenCalendarIDs), forKey: "hiddenCalendarIDs")
            refresh()
        }
    }

    private var timers: [Timer] = []

    init() {
        hiddenCalendarIDs = Set(UserDefaults.standard.stringArray(forKey: "hiddenCalendarIDs") ?? [])

        NotificationCenter.default.addObserver(forName: .EKEventStoreChanged, object: store, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        NotificationCenter.default.addObserver(forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.syncNow() }
        }
        timers.append(Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.now = .now }
        })
        timers.append(Timer.scheduledTimer(withTimeInterval: 180, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.syncNow() }
        })
        refresh()
    }

    var hasAccess: Bool { status == .fullAccess }
    var isDenied: Bool { status == .denied || status == .restricted || status == .writeOnly }
    var hasGoogleAccount: Bool { calendars.contains(where: \.isGoogle) }

    func requestAccess() async {
        if status == .notDetermined {
            _ = try? await store.requestFullAccessToEvents()
        }
        status = EKEventStore.authorizationStatus(for: .event)
        if isDenied { Self.openPrivacySettings() }
        syncNow()
    }

    /// Asks macOS to pull fresh data from Google (and other accounts), then reloads.
    func syncNow() {
        status = EKEventStore.authorizationStatus(for: .event)
        guard hasAccess else { return }
        store.refreshSourcesIfNecessary()
        refresh()
    }

    func refresh() {
        now = .now
        guard hasAccess else {
            events = []
            calendars = []
            return
        }

        let ekCalendars = store.calendars(for: .event)
        calendars = ekCalendars.map { c in
            let account = c.source?.title ?? "Other"
            let lower = account.lowercased()
            return CalendarInfo(
                id: c.calendarIdentifier, title: c.title, account: account, color: Color(nsColor: c.color),
                isGoogle: lower.contains("google") || lower.contains("gmail")
            )
        }
        .sorted { ($0.isGoogle ? 0 : 1, $0.account, $0.title) < ($1.isGoogle ? 0 : 1, $1.account, $1.title) }

        let visible = ekCalendars.filter { !hiddenCalendarIDs.contains($0.calendarIdentifier) }
        guard !visible.isEmpty else {
            events = []
            lastRefreshed = .now
            return
        }

        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -30, to: cal.startOfDay(for: .now))!
        let end = cal.date(byAdding: .day, value: 90, to: cal.startOfDay(for: .now))!
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: visible)

        events = store.events(matching: predicate)
            .filter { $0.status != .canceled }
            .map { e in
                CalendarEvent(
                    id: "\(e.eventIdentifier ?? UUID().uuidString)-\(e.startDate.timeIntervalSince1970)",
                    eventIdentifier: e.eventIdentifier ?? "",
                    title: e.title?.isEmpty == false ? e.title : "(No title)",
                    start: e.startDate,
                    end: e.endDate,
                    isAllDay: e.isAllDay,
                    location: e.location,
                    notes: e.notes,
                    calendarID: e.calendar.calendarIdentifier,
                    calendarTitle: e.calendar.title,
                    accountTitle: e.calendar.source?.title ?? "",
                    color: Color(nsColor: e.calendar.color),
                    meeting: MeetingLink.find(in: [e.url?.absoluteString, e.location, e.notes]),
                    attendeeCount: e.attendees?.count ?? 0
                )
            }
            .sorted { ($0.isAllDay ? 0 : 1, $0.start) < ($1.isAllDay ? 0 : 1, $1.start) }
        lastRefreshed = .now
    }

    // MARK: Queries

    func events(on day: Date) -> [CalendarEvent] {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: day)
        let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart)!
        return events.filter { $0.start < dayEnd && $0.end > dayStart }
    }

    func upcomingMeetings(days: Int = 30) -> [CalendarEvent] {
        let limit = Calendar.current.date(byAdding: .day, value: days, to: now)!
        return events
            .filter { $0.meeting != nil && $0.end > now && $0.start < limit && !$0.isAllDay }
            .sorted { $0.start < $1.start }
    }

    var nextMeeting: CalendarEvent? {
        let horizon = now.addingTimeInterval(12 * 3600)
        return upcomingMeetings(days: 2).first { $0.start < horizon }
    }

    var nextEvent: CalendarEvent? {
        events.filter { !$0.isAllDay && $0.end > now && Calendar.current.isDateInToday($0.start) }
            .min { $0.start < $1.start }
    }

    func search(_ text: String) -> [CalendarEvent] {
        let q = text.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        return events.filter { $0.title.lowercased().contains(q) && $0.end > now }
    }

    // MARK: Actions

    static func join(_ event: CalendarEvent) {
        if let url = event.meeting?.url { NSWorkspace.shared.open(url) }
    }

    static func openInCalendar(_ event: CalendarEvent) {
        if let url = URL(string: "ical://ekevent/\(event.eventIdentifier)?method=show&options=more") {
            NSWorkspace.shared.open(url)
        }
    }

    static func openInternetAccounts() {
        let urls = [
            "x-apple.systempreferences:com.apple.Internet-Accounts-Settings.extension",
            "x-apple.systempreferences:com.apple.preferences.internetaccounts",
        ]
        for s in urls { if let u = URL(string: s), NSWorkspace.shared.open(u) { return } }
    }

    static func openPrivacySettings() {
        if let u = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
            NSWorkspace.shared.open(u)
        }
    }
}
