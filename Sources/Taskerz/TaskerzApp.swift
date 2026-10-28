import SwiftUI

extension Notification.Name {
    static let focusQuickAdd = Notification.Name("taskerz.focusQuickAdd")
    static let newList = Notification.Name("taskerz.newList")
}

@main
struct TaskerzApp: App {
    @StateObject private var store = TaskStore()
    @StateObject private var calendar = CalendarService()
    @AppStorage("showMenuBarExtra") private var showMenuBarExtra = true

    var body: some Scene {
        WindowGroup("Taskerz", id: "main") {
            ContentView()
                .environmentObject(store)
                .environmentObject(calendar)
                .frame(minWidth: 860, minHeight: 540)
        }
        .defaultSize(width: 1180, height: 760)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Task") { NotificationCenter.default.post(name: .focusQuickAdd, object: nil) }
                    .keyboardShortcut("n")
                Button("New List") { NotificationCenter.default.post(name: .newList, object: nil) }
                    .keyboardShortcut("n", modifiers: [.command, .shift])
            }
            CommandMenu("Calendar") {
                Button("Sync Calendar Now") { calendar.syncNow() }
                    .keyboardShortcut("r")
            }
        }

        MenuBarExtra("Taskerz", systemImage: "checklist", isInserted: $showMenuBarExtra) {
            MenuBarView()
                .environmentObject(store)
                .environmentObject(calendar)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(store)
                .environmentObject(calendar)
        }
    }
}
