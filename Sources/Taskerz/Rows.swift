import SwiftUI
import AppKit

// MARK: - Task row

struct TaskRow: View {
    let task: TaskItem
    var showList = true
    let onInspect: () -> Void

    @EnvironmentObject private var store: TaskStore
    @EnvironmentObject private var calendar: CalendarService
    @State private var hovering = false

    private var list: TaskList? { store.list(task.listID) }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            StatusButton(task: task, tint: list?.color.color ?? .accentColor)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    if task.priority != .none {
                        Text(task.priority.marks)
                            .font(.system(size: 13.5, weight: .heavy))
                            .foregroundStyle(task.isDone ? Color.secondary : Color.orange)
                    }
                    Text(task.title)
                        .font(.system(size: 13.5))
                        .foregroundStyle(task.isDone ? .secondary : .primary)
                        .strikethrough(task.isDone, color: .secondary)
                        .lineLimit(2)
                }

                if let line = task.notes.split(separator: "\n").first, !line.isEmpty {
                    Text(line)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                MetaLine(task: task, list: showList ? list : nil, now: calendar.now)
            }

            Spacer(minLength: 8)

            Button(action: onInspect) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
            .opacity(hovering ? 1 : 0)
            .help("Show details")
        }
        .padding(.vertical, 5)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .opacity(task.isDone ? 0.75 : 1)
    }
}

struct StatusButton: View {
    let task: TaskItem
    let tint: Color

    @EnvironmentObject private var store: TaskStore
    @State private var hovering = false

    var body: some View {
        Button {
            store.toggleDone(task.id)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(color)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 20, height: 20)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help(task.isDone ? "Mark as not completed" : "Mark as completed")
    }

    private var symbol: String {
        if task.isDone { return "checkmark.circle.fill" }
        if hovering { return "checkmark.circle" }
        return task.status.symbol
    }

    private var color: Color {
        switch task.status {
        case .done: tint
        case .inProgress: .orange
        case .todo: hovering ? tint : Color.secondary.opacity(0.55)
        }
    }
}

struct MetaLine: View {
    let task: TaskItem
    let list: TaskList?
    let now: Date

    var body: some View {
        let state = task.dueState(now: now)
        let hasContent = task.status == .inProgress || task.dueLabel != nil || !task.tags.isEmpty
            || list != nil || task.linkedEventID != nil
        if hasContent {
            HStack(spacing: 6) {
                if task.status == .inProgress {
                    Pill(text: "Working On", symbol: "timer", tint: .orange, filled: true)
                }
                if let label = task.dueLabel {
                    Pill(text: state == .overdue ? "Overdue · \(label)" : label,
                         symbol: state == .overdue ? "exclamationmark.circle.fill" : "calendar",
                         tint: task.isDone ? .secondary : state.tint, filled: state == .overdue)
                }
                if task.linkedEventID != nil {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                }
                ForEach(task.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                }
                if let list {
                    HStack(spacing: 4) {
                        Circle().fill(list.color.color).frame(width: 7, height: 7)
                        Text(list.name)
                    }
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                }
            }
            .lineLimit(1)
        }
    }
}

// MARK: - Pills

struct Pill: View {
    let text: String
    var symbol: String?
    var tint: Color
    var filled = false

    var body: some View {
        HStack(spacing: 3) {
            if let symbol { Image(systemName: symbol).font(.system(size: 9.5, weight: .bold)) }
            Text(text).font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(filled ? .white : tint)
        .padding(.horizontal, 7)
        .padding(.vertical, 2.5)
        .background(Capsule().fill(filled ? AnyShapeStyle(tint.gradient) : AnyShapeStyle(tint.opacity(0.13))))
        .fixedSize()
    }
}

struct LiveBadge: View {
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(.red)
                .frame(width: 6, height: 6)
                .opacity(pulse ? 0.35 : 1)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
            Text("LIVE").font(.system(size: 9.5, weight: .heavy)).foregroundStyle(.red)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Capsule().fill(.red.opacity(0.12)))
        .onAppear { pulse = true }
    }
}

// MARK: - Event row

struct EventRow: View {
    let event: CalendarEvent
    @EnvironmentObject private var store: TaskStore
    @EnvironmentObject private var calendar: CalendarService

    var body: some View {
        let now = calendar.now
        let past = event.end < now
        HStack(spacing: 11) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(event.color.gradient)
                .frame(width: 4, height: 32)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(event.title)
                        .font(.system(size: 13.5, weight: .medium))
                        .lineLimit(1)
                    if event.isLive(at: now) { LiveBadge() }
                }
                HStack(spacing: 5) {
                    Text(event.timeLabel)
                    Text("·")
                    Text(event.calendarTitle).lineLimit(1)
                    if let meeting = event.meeting {
                        Text("·")
                        Image(systemName: "video.fill").foregroundStyle(meeting.tint)
                        Text(meeting.title).foregroundStyle(meeting.tint)
                    }
                    if event.attendeeCount > 1 {
                        Text("·")
                        Image(systemName: "person.2.fill")
                        Text("\(event.attendeeCount)")
                    }
                }
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            if !past, !event.isLive(at: now), !event.isAllDay, event.start.timeIntervalSince(now) < 4 * 3600 {
                Text(event.relativeLabel(now: now))
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            if let meeting = event.meeting, !past {
                Button {
                    CalendarService.join(event)
                } label: {
                    Label("Join", systemImage: "video.fill")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(meeting.tint)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
        .opacity(past ? 0.5 : 1)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { CalendarService.openInCalendar(event) }
        .contextMenu { EventMenu(event: event) }
    }
}

struct EventMenu: View {
    let event: CalendarEvent
    @EnvironmentObject private var store: TaskStore

    var body: some View {
        if let meeting = event.meeting {
            Button("Join \(meeting.title)") { CalendarService.join(event) }
            Button("Copy Meeting Link") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(meeting.url.absoluteString, forType: .string)
            }
            Divider()
        }
        Button("Create Task from Event") { store.addTask(from: event) }
        Button("Open in Calendar") { CalendarService.openInCalendar(event) }
    }
}

// MARK: - Next meeting card

struct NextMeetingCard: View {
    let event: CalendarEvent
    @EnvironmentObject private var calendar: CalendarService

    var body: some View {
        let tint = event.meeting?.tint ?? .accentColor
        let live = event.isLive(at: calendar.now)
        HStack(spacing: 14) {
            Image(systemName: "video.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(tint.gradient))
                .shadow(color: tint.opacity(0.35), radius: 6, y: 3)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(live ? "HAPPENING NOW" : "UP NEXT")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundStyle(tint)
                    if live { LiveBadge() }
                }
                Text(event.title)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                Text("\(event.timeLabel) · \(event.relativeLabel(now: calendar.now)) · \(event.meeting?.title ?? "")")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Button {
                CalendarService.join(event)
            } label: {
                Label("Join", systemImage: "video.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(tint)
            .controlSize(.large)
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tint.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(tint.opacity(0.18)))
        }
        .contextMenu { EventMenu(event: event) }
    }
}

// MARK: - Calendar connect card

struct CalendarConnectCard: View {
    @EnvironmentObject private var calendar: CalendarService

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                VStack(spacing: 0) {
                    Rectangle().fill(.red.gradient).frame(height: 13)
                    Text(Date.now.formatted(.dateTime.day()))
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.black)
                        .frame(maxHeight: .infinity)
                }
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 6) {
                Text(calendar.isDenied ? "Calendar access is turned off" : "Connect your Google Calendar")
                    .font(.system(size: 15, weight: .semibold))
                Text(calendar.isDenied
                     ? "Turn on Taskerz in System Settings › Privacy & Security › Calendars to see your meetings."
                     : "Taskerz shows your Google Calendar events and Google Meet links automatically. Add your Google account to macOS, then allow access.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    Button {
                        Task { await calendar.requestAccess() }
                    } label: {
                        Text(calendar.isDenied ? "Open Privacy Settings" : "Allow Calendar Access")
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Add Google Account…") { CalendarService.openInternetAccounts() }
                        .buttonStyle(.bordered)
                }
                .controlSize(.regular)
                .padding(.top, 4)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.primary.opacity(0.07)))
        }
    }
}

// MARK: - Context menu

struct TaskMenu: View {
    let ids: Set<UUID>
    let onInspect: (UUID) -> Void
    @EnvironmentObject private var store: TaskStore

    var body: some View {
        if ids.count == 1, let id = ids.first {
            Button("Show Info") { onInspect(id) }
            Divider()
        }

        Menu("Status") {
            ForEach(TaskStatus.allCases) { s in
                Button { store.setStatus(s, for: ids) } label: { Label(s.title, systemImage: s.symbol) }
            }
        }

        Menu("Due Date") {
            let cal = Calendar.current
            let today = cal.startOfDay(for: .now)
            Button("Today") { setDue(today) }
            Button("Tomorrow") { setDue(cal.date(byAdding: .day, value: 1, to: today)) }
            Button("This Weekend") { setDue(cal.nextWeekend(startingAfter: today)?.start) }
            Button("Next Week") { setDue(cal.date(byAdding: .day, value: 7, to: today)) }
            Divider()
            Button("Remove Due Date") { setDue(nil) }
        }

        Menu("Priority") {
            ForEach(Priority.allCases.reversed()) { p in
                Button(p == .none ? "None" : "\(p.marks)  \(p.title)") {
                    for id in ids { store.mutate(id) { $0.priority = p } }
                }
            }
        }

        Menu("Move to List") {
            ForEach(store.lists) { list in
                Button { for id in ids { store.mutate(id) { $0.listID = list.id } } } label: {
                    Label(list.name, systemImage: list.symbol)
                }
            }
        }

        Divider()
        Button(ids.count > 1 ? "Delete \(ids.count) Tasks" : "Delete", role: .destructive) {
            store.delete(ids)
        }
    }

    private func setDue(_ date: Date?) {
        for id in ids {
            store.mutate(id) {
                $0.dueDate = date
                $0.hasDueTime = false
            }
        }
    }
}

// MARK: - Flow layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, width: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            width = max(width, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
