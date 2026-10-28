# Taskerz

A native macOS to-do app (SwiftUI) with statuses, tags, due dates, a Kanban board, and your Google Calendar + Google Meet links built in.

## Build & run

```sh
./build.sh --open
```

Requires macOS 14+ and the Xcode Command Line Tools (`xcode-select --install`). The script compiles a release build, assembles `Taskerz.app`, and signs it locally. Drag `Taskerz.app` to `/Applications` to keep it.

## Release DMGs

```sh
./release.sh                          # → dist/Taskerz-1.0.0-{Universal,AppleSilicon,Intel}.dmg
VERSION=1.1.0 BUILD=2 ./release.sh    # bump version
```

Builds arm64 + x86_64, merges them into a universal app, signs with Hardened Runtime, and packages three drag-to-Applications DMGs with SHA-256 checksums. Ship **Universal** as the main download. The per-architecture DMGs are smaller alternatives.

### Warning-free public distribution (Developer ID + notarization)

Without an Apple signature, people who download the app see *“Apple could not verify Taskerz”* and must click **System Settings › Privacy & Security › Open Anyway**. To remove that:

1. Join the [Apple Developer Program](https://developer.apple.com/programs/) ($99/year).
2. Create a **Developer ID Application** certificate (Xcode › Settings › Accounts › Manage Certificates, or developer.apple.com) and install it in your keychain.
3. Store notarization credentials once (use an [app-specific password](https://account.apple.com)):
   ```sh
   xcrun notarytool store-credentials taskerz-notary \
     --apple-id you@example.com --team-id TEAMID --password xxxx-xxxx-xxxx-xxxx
   ```
4. Release:
   ```sh
   DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)" \
   NOTARY_PROFILE=taskerz-notary VERSION=1.0.0 ./release.sh
   ```
   The script signs the app and DMGs, submits them to Apple, and staples the notarization ticket.

## Connect Google Calendar

Taskerz reads Google Calendar through macOS, so no Google sign-in or API keys are needed:

1. **System Settings › Internet Accounts › Add Account › Google**, sign in, and turn on **Calendars**.
2. In Taskerz click **Allow Calendar Access**.

Events appear in **Today**, **Upcoming** and **Calendar**. Any event with a Google Meet (or Zoom / Teams / Webex) link shows up in **Meetings** with a **Join** button. Changes sync automatically. Press ⌘R to sync on demand. Choose which calendars are shown in Settings › Calendar.

## Features

| | |
|---|---|
| **Statuses** | To Do · Working On · Completed (click the circle, right-click › Status, or drag between board columns) |
| **Due tracking** | Due dates with optional time; Today / Overdue / Upcoming smart lists; red overdue badges |
| **Tags & priority** | `#tags`, `!` `!!` `!!!` priorities, tag smart lists in the sidebar |
| **Lists** | Custom colored lists with icons; drag tasks onto a list to move them |
| **Views** | List or Board (Kanban) for every task view; sort by smart / due / priority / title / created |
| **Calendar** | Month grid with event/task dots, day agenda, next-meeting card, create a task from any event |
| **Menu bar** | Today's tasks, next meeting with Join, and quick add from the menu bar |
| **Quick add** | `Call Alex tomorrow 4pm #work !!` → due tomorrow 4 PM, tagged `work`, medium priority |

## Shortcuts

| Key | Action |
|---|---|
| ⌘N | New task |
| ⇧⌘N | New list |
| ⌘I | Show task details |
| ⌘R | Sync calendar |
| ⌫ | Delete selected tasks |
| Double-click | Open task details / open event in Calendar |

## Data

Tasks are stored locally in `~/Library/Application Support/Taskerz/data.json`.

## Project layout

```
Sources/Taskerz/
  TaskerzApp.swift      App, menus, menu bar extra, settings scene
  Models.swift          TaskItem, TaskList, statuses, priorities, sidebar items
  TaskStore.swift       Persistence, CRUD, queries, quick-add parser
  CalendarService.swift EventKit access, Google/Meet detection, auto refresh
  ScreenBuilder.swift   What each sidebar item shows
  ContentView.swift     Split view, search, inspector
  SidebarView.swift     Smart tiles, lists, tags, list editor
  TaskScreen.swift      List view, header, quick add bar, toolbar
  BoardView.swift       Kanban board with drag & drop
  CalendarScreen.swift  Month grid + day agenda
  MonthGrid.swift       Calendar.app-style month picker
  Rows.swift            Task/event rows, pills, meeting card, context menu
  TaskInspector.swift   Task details panel
  MenuBarView.swift     Menu bar popover
  SettingsView.swift    Settings window
Support/                Info.plist and icon generator
```
