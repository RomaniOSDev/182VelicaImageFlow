import SwiftUI

struct TimelineView: View {
    @EnvironmentObject private var store: MoodSyncDataStore
    @State private var displayedMonth = Date()
    @State private var selectedDay = Date()

    private let calendar = Calendar.current
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            monthHeader
            weekdayHeader
            calendarGrid
            dayItemsList
        }
    }

    private var monthHeader: some View {
        HStack {
            HeaderIconButton(systemImage: "chevron.left") {
                displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
            }
            Spacer()
            Text(monthTitle(displayedMonth))
                .font(.headline)
                .foregroundStyle(Color("AppTextPrimary"))
            Spacer()
            HeaderIconButton(systemImage: "chevron.right") {
                displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
            }
        }
    }

    private var weekdayHeader: some View {
        HStack {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color("AppTextSecondary"))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var calendarGrid: some View {
        let days = daysInMonth(displayedMonth)
        let active = store.activeCalendarDates(for: displayedMonth)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(day, isActive: active.contains(calendar.startOfDay(for: day)))
                } else {
                    Color.clear.frame(height: 44)
                }
            }
        }
    }

    private func dayCell(_ day: Date, isActive: Bool) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDay)
        return Button {
            FeedbackManager.tapLight()
            selectedDay = day
        } label: {
            VStack(spacing: 5) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.subheadline.weight(isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? Color("AppBackground") : Color("AppTextPrimary"))
                Circle()
                    .fill(isActive ? Color("AppAccent") : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [Color("AppPrimary"), Color("AppAccent")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color("AppBackground").opacity(0.45)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isActive && !isSelected ? Color("AppAccent").opacity(0.6) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var dayItemsList: some View {
        let items = store.timelineItems(on: selectedDay)
        return VStack(alignment: .leading, spacing: 10) {
            Text("Activity · \(shortDate(selectedDay))")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("AppTextSecondary"))
            if items.isEmpty {
                Text("No activity on this day.")
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .padding(.vertical, 8)
            } else {
                ForEach(items) { item in
                    TimelineActivityCell(item: item)
                }
            }
        }
    }

    private func monthTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func daysInMonth(_ date: Date) -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: date),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            return []
        }
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: leading)
        for day in range {
            if let d = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(d)
            }
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }
}
