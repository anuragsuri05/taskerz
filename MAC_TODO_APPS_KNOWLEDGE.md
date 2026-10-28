# Mac To-Do / Task Manager Apps — Knowledge Base

> Compiled: 2026-10-11 from web research (sources at bottom).
> Prices change often and sources disagree — figures marked `~` are approximate/unverified. Re-check official pricing pages before quoting.

---

## 1. Quick comparison table

| App | Pricing model | Approx. price | Platforms | Native Mac? | Collaboration | AI | Best for |
|---|---|---|---|---|---|---|---|
| **Apple Reminders** | Free (bundled) | $0 | Mac, iPhone, iPad, Watch, iCloud web | Yes | List sharing + assignment | Apple Intelligence (auto-sections, suggestions) | Simple, Apple-only users |
| **Things 3** | One-time per platform | Mac $49.99, iPad $19.99, iPhone $9.99, Vision $29.99 | Apple only (no web/Android/Windows) | Yes (gold-standard design) | None | None | Elegant personal task mgmt |
| **OmniFocus 4** | One-time or subscription | Standard $74.99, Pro $149.99, sub ~$99.99/yr, web from $4.99/mo | Apple + Web | Yes | None (personal) | Optional Apple Intelligence plugins (Omni Automation) | GTD power users |
| **Todoist** | Freemium subscription | Pro ~$5/mo yearly ($60/yr), ~$7 monthly; Business per member | All (Mac, Win, Linux, iOS, Android, Web) | Electron-ish but polished | Yes (Business workspace) | Task Assist, Ramble (voice) | Cross-platform all-rounder |
| **TickTick** | Freemium subscription | Premium $35.99/yr (~$3.99/mo) | All + Watch | Respects macOS conventions | Shared lists | Limited | Feature-rich value pick (Pomodoro, habits) |
| **Microsoft To Do** | Free | $0 | All | No | Shared lists | No | Outlook/M365 users |
| **GoodTask** | One-time (or Setapp) | Mac $39.99; iOS $19.99 unlock | Apple | Yes | via Reminders sharing | No | Power layer over Apple Reminders |
| **2Do** | One-time (or Setapp) | Mac $49.99; iOS $9.99; Android free (+$9.99 sync) | Apple + Android | Yes (dated UI) | No | No | Customization + many sync backends |
| **Superlist** | Freemium | Free; paid tier ~ | Mac, iOS, Web | Fast, animated | Free sharing up to 5 people | Some | Small teams; notes + tasks |
| **Akiflow** | Subscription | ~$19/mo+ | Mac, Win, iOS, Android, Web | No | Limited | Some | Time-blocking, inbox consolidation |
| **Motion** | Subscription | ~$29–49/mo | Web/Mac/mobile | No (web port) | Yes (teams) | Core: AI auto-scheduling | People who want the calendar planned for them |
| **Structured** | Freemium / lifetime | Lifetime option; AI is premium | Mac, iOS, Android | Yes | No | Voice task entry (premium) | Daily timeline/routines, ADHD-friendly |
| **Blitzit** | Sub or lifetime | Lifetime option | Mac (menu bar) | Yes | No | No | Focus timers, task stacking |
| **Lunatask** | Freemium | ~ | Mac, Win, Linux, mobile | No | No | No | Privacy (end-to-end encrypted tasks/notes/journal) |
| **Any.do** | Freemium | ~ | All | No | Family/team lists | Some | Personal + family, daily planner |
| **Godspeed** | Subscription | ~ | Mac/Web/iOS | Yes | No | No | Keyboard-driven speed users |
| **Griply** | Freemium | ~ | Mac, iOS | Yes | No | No | Goals + habits + tasks, offline |
| **PopTask** | ~ | ~ | Mac menu bar | Yes | No | NL date parsing (on-device + cloud fallback) | Quick capture from menu bar |
| **TaskTab / PreForget** | Free | $0 | Mac menu bar | Yes | No | PreForget: light AI | Ultra-minimal menu-bar lists |
| **Todo.txt / TodoTxtMac** | Free, open source | $0 | Any (plain text) | GUI available | No | No | Plain-text, portable, dev-friendly |

---

## 2. Detailed app profiles

### Apple Reminders (built-in)
- **Features:** lists, tags, due dates, subtasks, Smart Lists, location-based alerts, auto-categorized grocery lists, Siri, Calendar integration, iCloud sync, shared lists with assignment.
- **macOS 26 (Tahoe):** Apple Intelligence can auto-group reminders into sections and suggest tasks, grocery items, and follow-ups from Mail/Messages. Shortcuts can call Apple's models and act on Reminders.
- **Weaknesses:** the Mac app feels thin, there's no global quick-add shortcut, and it gets messy at scale.
- **Ecosystem note:** its EventKit backend lets 3rd-party apps (GoodTask, etc.) build on top of it. This is a major integration point for any new Mac app.

### Things 3 (Cultured Code)
- **Model:** paid once per platform. No subscription. 15-day trial on Mac.
- **Structure:** Areas → Projects → Headings → To-dos → Checklists (subtasks), with notes. "Today", "This Evening", "Upcoming", "Anytime", "Someday", and "Logbook".
- **Features:** system-wide Quick Entry (with autofill from the frontmost app), calendar events shown in Today/Upcoming, deep keyboard shortcuts, Magic Plus button, URL scheme, AppleScript, Shortcuts, Mail to Things, Zapier.
- **Recent:** 3.22 (fall 2025) added OS 26 compatibility and Liquid Glass. 3.23 (Aug 2026) reworked repeating tasks: you can complete a repeat early and move a single instance of a series. **No Things 4 has been announced.**
- **Weaknesses:** no web/Android/Windows, no collaboration or sharing, slow feature cadence.
- **Why people love it:** design, delight, and a calm UI. It's the benchmark for "feels native".

### OmniFocus 4 (The Omni Group)
- **Version:** 4.9.x (Apple), plus a web app. Requires macOS 15.2+.
- **Model:** one-time Standard ($74.99) or Pro ($149.99), or a subscription covering all platforms plus web. 14-day trial.
- **Features:** Inbox, Projects (parallel / sequential / single-action), Tags, Forecast, **Review** (guided weekly review), **Perspectives** (custom saved views, Pro), defer dates vs due dates, Someday/Maybe, Omni Automation (JavaScript plugins, including Apple Intelligence plugins), Focus mode, Quick Entry, Zapier.
- **Weaknesses:** steep learning curve, expensive, can feel cluttered.
- **Key concept:** **defer (start) dates** hide tasks until they're actionable. GTD users consider this essential.

### Todoist (Doist)
- **Plans:** *Beginner* (free: 5 projects, 3 filters, reminders, list+board views, 1 week of activity history). *Pro* (300 projects, calendar layout, task durations, deadlines, 150 filters, Task Assist AI, unlimited Ramble voice capture). *Business* (team workspace, up to 500 team projects, roles, shared templates, admin billing).
- **Price:** Pro rose from $48/yr to **$60/yr in Dec 2025**. Monthly billing is about $7.
- **Standout:** best-in-class **natural-language Quick Add** ("Pay rent every 1st #Home p1 @bills"), filters query language, 80+ integrations, Karma gamification, menu bar app, widgets, works offline.
- **Weaknesses:** no built-in timer/Pomodoro, the calendar view is Pro-only, and it's subscription only.

### TickTick
- **Price:** free tier. Premium is about **$35.99/yr**, roughly 40% cheaper than Todoist Pro.
- **Features:** lists, tags, smart lists, NL parsing, **calendar views** (day/week/month, Premium), **Eisenhower Matrix**, **Kanban**, **Pomodoro/focus timer**, **habit tracker**, menu bar, global shortcut, Apple Watch, Zapier.
- **Weaknesses:** its web-app roots show sometimes, and it's feature-dense to the point of clutter.

### Microsoft To Do
- Free and cross-platform. "My Day" daily planning, Outlook tasks/flagged email integration, shared lists. Not a native Mac app, and light on power features.

### GoodTask
- A power UI on top of Apple Reminders and Calendar: advanced smart lists, a calendar plus tasks view, quick actions, and a global shortcut. Mac costs $39.99. Also on Setapp.

### 2Do
- Very customizable: lists, projects, checklists, tags, smart lists. Syncs via iCloud, Dropbox, CalDAV, Toodledo, and more. Mac costs $49.99. Its UI looks dated.

### Superlist
- From the Wunderlist founders. Notes and tasks live in one doc-like list. Fast, with gestures and animations. Free collaboration for up to 5 people. No calendar view.

### Akiflow
- A "universal inbox" that pulls tasks from email, Slack, Notion, and more, then time-blocks them on Google/Outlook calendars. Has a menu bar meeting view and a command bar. About $19/mo or more.

### Motion
- AI auto-schedules tasks into your calendar and reshuffles them when meetings move. About $29–49/mo. No offline mode. Built for teams and busy individuals.

### Structured
- A visual daily timeline that merges tasks, events, and routines. Works offline. Premium AI voice entry. Popular with ADHD users.

### Blitzit
- Menu-bar focus app: "task stacking", per-task timers, Pomodoro, Notion import. Lifetime pricing available.

### Lunatask
- End-to-end encrypted all-in-one: tasks, habits, notes, journal, mood. Privacy focused.

### Godspeed
- Keyboard-first, very fast, minimal mouse use. Inspired by vim/Superhuman.

### Griply
- Goals, then habits, then tasks hierarchy. Works offline.

### Menu bar micro-apps
- **PopTask:** quick capture with an AI pipeline that parses dates, times, and recurrence, cleans titles, and sets reminders. On-device first, with GPT-4o-mini as a cloud fallback. It hit #2 on Product Hunt on Mar 30, 2026. Its privacy claims are inconsistent across sources.
- **TaskTab:** free, a simple list with a hotkey.
- **PreForget:** free, with urgency-based sorting and light AI.

### Plain text
- **Todo.txt** (CLI, open format) and **TodoTxtMac** (GUI). They're portable and git-friendly.

---

## 3. Feature taxonomy (what Mac to-do apps compete on)

**Capture**
- Global hotkey Quick Entry window (Things, OmniFocus, Todoist, TickTick). Users expect this on Mac.
- Menu bar presence (Todoist, TickTick, Blitzit, PopTask).
- Natural-language parsing of dates, recurrence, tags, priority, and project (Todoist is the benchmark).
- Capture from the current context: Mail, Safari URL, selected text (Things autofill, share extensions).
- Voice capture (Todoist Ramble, Structured, Siri).

**Organization**
- Hierarchy: Areas/Folders → Projects → Sections/Headings → Tasks → Subtasks/Checklists.
- Tags/labels, priorities, smart lists/filters/perspectives.
- Start/defer dates vs due/deadline dates (Things "When" vs "Deadline", OmniFocus defer vs due).
- Someday/Maybe, Logbook/completed history.

**Planning views**
- Today / Upcoming / Forecast. List, board/Kanban, calendar (day/week/month), timeline.
- Eisenhower Matrix (TickTick). Time-blocking (Akiflow, Motion, Structured).
- Weekly review (OmniFocus).

**Execution**
- Pomodoro/focus timers (TickTick, Blitzit), task durations, habits (TickTick, Griply, Lunatask).

**Recurrence**
- Repeat on schedule vs repeat after completion. Complete early (Things 3.23). Edit a single instance vs the whole series.

**Platform integration (the "native Mac" bar)**
- Native notifications, widgets, Shortcuts/App Intents, AppleScript/URL schemes, Spotlight, Siri, Apple Intelligence, calendar overlay (EventKit), Handoff, iCloud/CloudKit sync, keyboard-first navigation, Liquid Glass (macOS 26) styling.

**Collaboration**
- Shared lists/projects, assignment, comments (Todoist, Superlist, Reminders, Any.do). Things and OmniFocus have none.

**AI (2025–26 trend)**
- NL parsing, auto-categorization, task breakdown (Todoist Task Assist), auto-scheduling (Motion), email/message follow-up suggestions (Apple Reminders), voice brain-dump to tasks (Ramble).

**Privacy**
- Local-first or E2E encryption (Lunatask). iCloud-only sync (Things uses its own cloud). Account-less (PopTask, menu-bar apps).

---

## 4. Pricing landscape

- **One-time purchase:** Things, OmniFocus (Standard/Pro), GoodTask, 2Do, some lifetime plans (Blitzit, Structured). Mac users strongly value this, and "no subscription" is a selling point.
- **Cheap subscription:** TickTick (~$36/yr), Todoist (~$60/yr).
- **Premium subscription:** Akiflow (~$19/mo+), Motion (~$29–49/mo), justified by calendar/AI scheduling.
- **Free:** Apple Reminders, Microsoft To Do, Todo.txt, the free tiers of Todoist, TickTick, and Superlist.
- **Bundles:** Setapp (~$10/mo) includes GoodTask, 2Do, and others.

---

## 5. Common user complaints / market gaps (opportunities for Taskerz)

1. **Things is beautiful but stagnant:** no collaboration, no web, few new features.
2. **OmniFocus is powerful but intimidating:** steep learning curve.
3. **Todoist/TickTick feel less native:** web-tech roots, subscription fatigue, Todoist's 2025 price hike.
4. **Reminders is free but shallow on Mac:** no global quick-add, weak organization at scale.
5. **AI schedulers (Motion) are expensive** and need constant connectivity.
6. **Few apps combine** native Mac polish, a one-time price, light collaboration, and on-device AI with good privacy.
7. **Timers and habits** live in TickTick/Blitzit but are missing from the "beautiful" apps.
8. **Recurring-task edge cases** (complete early, skip one, edit one instance) are still being fixed in 2026, even in Things.

**Table-stakes checklist for a credible new Mac to-do app:**
- [ ] Global hotkey quick entry + menu bar
- [ ] Natural-language dates/recurrence
- [ ] Today / Upcoming / Someday views
- [ ] Projects + tags + subtasks + notes
- [ ] Calendar events shown alongside tasks (EventKit)
- [ ] Native notifications, widgets, Shortcuts/App Intents
- [ ] Full keyboard navigation
- [ ] iCloud/CloudKit sync + offline-first
- [ ] Dark mode + macOS 26 design language
- [ ] Import from Things / Todoist / Reminders

---

## Sources
- Zapier — Best Mac to-do list apps (updated Mar 2026): https://zapier.com/blog/best-mac-to-do-list-apps/
- ToolFinder — Best To-Do List Apps for Mac 2026: https://www.toolfinder.com/lists/to-do-apps-for-mac
- Todoist pricing: https://todoist.com/pricing
- OmniFocus product page: https://www.omnigroup.com/omnifocus/
- Things 3.23 report (BornCity): https://borncity.com/news/things-3-23-cultured-code-ueberarbeitet-wiederholungs-system/
- Cultured Code status: https://culturedcode.com/status
- Asian Efficiency — Todoist vs TickTick (Jul 2026): https://www.asianefficiency.com/task-management/todoist-vs-ticktick/
- Asian Efficiency — Todoist vs Things: https://www.asianefficiency.com/task-management/todoist-vs-things/
- Toolradar — Things 3 pricing: https://toolradar.com/tools/things-3/pricing
- Lifestack — To-do app for Mac: https://lifestack.ai/blog/to-do-list-app-for-mac
- Macworld — macOS Tahoe features: https://www.macworld.com/article/2809682/macos-26-tahoe-5-features-coming-this-fall-that-power-users-will-love.html
- Apple Newsroom — macOS Tahoe 26: https://www.apple.com/newsroom/2025/06/macos-tahoe-26-makes-the-mac-more-capable-productive-and-intelligent-than-ever/
- PopTask listing (Futurepedia): https://www.futurepedia.io/tool/poptask
