import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var store: TaskStore
    @EnvironmentObject private var calendar: CalendarService
    @Environment(\.openWindow) private var openWindow
    @State private var text = ""

    var body: some View {
        let today = TaskSort.smart.sorted(store.tasks(for: .today, now: calendar.now).filter { !$0.isDone })

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Today").font(.system(size: 17, weight: .bold)).foregroundStyle(.blue)
                    Text(calendar.now.formatted(.dateTime.weekday(.wide).month().day()))
                        .font(.system(size: 11.5)).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(today.count)")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.blue)
            }

            if let meeting = calendar.nextMeeting {
                HStack(spacing: 10) {
                    Image(systemName: "video.fill")
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill((meeting.meeting?.tint ?? .green).gradient))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(meeting.title).font(.system(size: 12.5, weight: .semibold)).lineLimit(1)
                        Text(meeting.relativeLabel(now: calendar.now)).font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Join") { CalendarService.join(meeting) }
                        .buttonStyle(.borderedProminent)
                        .tint(meeting.meeting?.tint ?? .green)
                        .controlSize(.small)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.primary.opacity(0.05)))
            } else if let event = calendar.nextEvent {
                Label("\(event.title) · \(event.relativeLabel(now: calendar.now))", systemImage: "calendar")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            VStack(alignment: .leading, spacing: 2) {
                if today.isEmpty {
                    Text("Nothing due today 🎉")
                        .font(.system(size: 12.5))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }
                ForEach(today.prefix(8)) { task in
                    HStack(spacing: 8) {
                        StatusButton(task: task, tint: store.list(task.listID)?.color.color ?? .accentColor)
                        Text(task.title).font(.system(size: 12.5)).lineLimit(1)
                        Spacer()
                        if task.dueState(now: calendar.now) == .overdue {
                            Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.red).font(.system(size: 11))
                        }
                    }
                    .padding(.vertical, 3)
                }
                if today.count > 8 {
                    Text("+\(today.count - 8) more").font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill").foregroundStyle(.blue)
                TextField("Add to Today", text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12.5))
                    .onSubmit {
                        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        store.addTask(QuickAddParser.parse(text),
                                      defaults: QuickAddDefaults(dueDate: Calendar.current.startOfDay(for: .now)))
                        text = ""
                    }
            }
            .padding(9)
            .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Color.primary.opacity(0.05)))

            Divider()

            HStack {
                Button("Open Taskerz") {
                    openWindow(id: "main")
                    NSApp.activate(ignoringOtherApps: true)
                }
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .font(.system(size: 12.5, weight: .medium))
        }
        .padding(16)
        .frame(width: 320)
    }
}
