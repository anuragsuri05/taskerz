import SwiftUI

/// A Calendar.app-style month picker with dots for days that have events or tasks.
struct MonthGrid: View {
    @Binding var selection: Date

    @EnvironmentObject private var store: TaskStore
    @EnvironmentObject private var calendar: CalendarService
    @State private var month = Calendar.current.startOfMonth(for: .now)

    private let cal = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(month.formatted(.dateTime.month(.wide)))
                    .font(.system(size: 17, weight: .bold))
                + Text(" " + month.formatted(.dateTime.year()))
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 2) {
                    navButton("chevron.left") { shiftMonth(-1) }
                    navButton("chevron.right") { shiftMonth(1) }
                }
            }

            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(height: 18)
                }
                ForEach(days, id: \.self) { day in
                    dayCell(day)
                }
            }
        }
        .onChange(of: selection) { _, new in
            let m = cal.startOfMonth(for: new)
            if m != month { withAnimation(.snappy) { month = m } }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let inMonth = cal.isDate(day, equalTo: month, toGranularity: .month)
        let isToday = cal.isDateInToday(day)
        let isSelected = cal.isDate(day, inSameDayAs: selection)
        let hasEvents = !calendar.events(on: day).isEmpty
        let hasTasks = store.tasks(dueOn: day).contains { !$0.isDone }

        return Button {
            withAnimation(.snappy) { selection = day }
        } label: {
            VStack(spacing: 2) {
                Text(day.formatted(.dateTime.day()))
                    .font(.system(size: 12.5, weight: isToday || isSelected ? .bold : .regular))
                    .monospacedDigit()
                    .foregroundStyle(isSelected ? .white : isToday ? .red : inMonth ? Color.primary : Color.secondary.opacity(0.5))
                    .frame(width: 28, height: 28)
                    .background {
                        if isSelected { Circle().fill(isToday ? Color.red.gradient : Color.primary.opacity(0.85).gradient) }
                    }
                HStack(spacing: 2) {
                    Circle().fill(hasEvents ? Color.red : .clear).frame(width: 4, height: 4)
                    Circle().fill(hasTasks ? Color.blue : .clear).frame(width: 4, height: 4)
                }
                .opacity(inMonth ? 1 : 0.4)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func navButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 26, height: 26)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
    }

    private func shiftMonth(_ delta: Int) {
        withAnimation(.snappy) {
            month = cal.date(byAdding: .month, value: delta, to: month) ?? month
        }
    }

    private var weekdaySymbols: [String] {
        let symbols = cal.veryShortStandaloneWeekdaySymbols
        let first = cal.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    /// Always six weeks so the grid height never jumps.
    private var days: [Date] {
        let offset = (cal.component(.weekday, from: month) - cal.firstWeekday + 7) % 7
        let start = cal.date(byAdding: .day, value: -offset, to: month)!
        return (0..<42).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? startOfDay(for: date)
    }
}
