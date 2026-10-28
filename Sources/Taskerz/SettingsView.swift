import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettings()
                .tabItem { Label("General", systemImage: "gearshape") }
            CalendarSettings()
                .tabItem { Label("Calendar", systemImage: "calendar") }
        }
        .frame(width: 520, height: 440)
    }
}

private struct GeneralSettings: View {
    @AppStorage("showCompleted") private var showCompleted = false
    @AppStorage("sort") private var sort: TaskSort = .smart
    @AppStorage("showMenuBarExtra") private var showMenuBarExtra = true

    var body: some View {
        Form {
            Section("Tasks") {
                Toggle("Show completed tasks", isOn: $showCompleted)
                Picker("Sort tasks by", selection: $sort) {
                    ForEach(TaskSort.allCases) { Text($0.title).tag($0) }
                }
            }
            Section("Menu Bar") {
                Toggle("Show Taskerz in the menu bar", isOn: $showMenuBarExtra)
            }
            Section("Quick Add Shortcuts") {
                LabeledContent("Dates", value: "tomorrow, fri 3pm, next monday")
                LabeledContent("Tags", value: "#work #home")
                LabeledContent("Priority", value: "!  !!  !!!  or  !high")
            }
        }
        .formStyle(.grouped)
    }
}

private struct CalendarSettings: View {
    @EnvironmentObject private var calendar: CalendarService

    var body: some View {
        Form {
            Section {
                HStack {
                    Label {
                        Text(statusText)
                    } icon: {
                        Image(systemName: calendar.hasAccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundStyle(calendar.hasAccess ? .green : .orange)
                    }
                    Spacer()
                    if calendar.hasAccess {
                        Button("Sync Now") { calendar.syncNow() }
                    } else {
                        Button(calendar.isDenied ? "Open Privacy Settings" : "Allow Access") {
                            Task { await calendar.requestAccess() }
                        }
                    }
                }
                LabeledContent("Google account") {
                    HStack {
                        Text(calendar.hasGoogleAccount ? "Connected" : "Not added")
                            .foregroundStyle(.secondary)
                        Button("Internet Accounts…") { CalendarService.openInternetAccounts() }
                    }
                }
            } header: {
                Text("Connection")
            } footer: {
                Text("Taskerz reads Google Calendar through macOS. Add your Google account in System Settings › Internet Accounts and turn on Calendars. Events and Google Meet links sync automatically.")
                    .foregroundStyle(.secondary)
            }

            if calendar.hasAccess {
                Section("Visible Calendars") {
                    CalendarToggleList()
                }
            }
        }
        .formStyle(.grouped)
    }

    private var statusText: String {
        if calendar.hasAccess { return "Calendar access allowed" }
        if calendar.isDenied { return "Calendar access denied" }
        return "Calendar access not set up"
    }
}
