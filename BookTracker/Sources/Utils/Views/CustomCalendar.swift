import SwiftUI

public struct CustomCalendar<DayContent: View>: View {
    private let calendar: Calendar
    @Binding private var monthDate: Date
    private var selection: Binding<Date?>?
    private let dayContent: (Date) -> DayContent
    private let showsHeader: Bool

    private var monthStart: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)) ?? monthDate
    }

    private var daysInMonth: Int {
        (calendar.range(of: .day, in: .month, for: monthStart)?.count) ?? 30
    }

    private var weekdaySymbols: [String] {
        calendar.shortStandaloneWeekdaySymbols
    }

    private var firstWeekday: Int { calendar.firstWeekday }

    private var leadingEmptyCount: Int {
        let weekdayOfFirst = calendar.component(.weekday, from: monthStart)
        return (weekdayOfFirst - firstWeekday + 7) % 7
    }

    private var totalCells: Int {
        let base = leadingEmptyCount + daysInMonth
        return ((base + 6) / 7) * 7
    }

    private var days: [Date?] {
        var result: [Date?] = Array(repeating: nil, count: leadingEmptyCount)
        for day in 1 ... daysInMonth {
            if let d = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                result.append(d)
            }
        }
        if result.count < totalCells {
            result.append(contentsOf: Array(repeating: nil, count: totalCells - result.count))
        }
        return result
    }

    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 6, alignment: .center), count: 7)

    public init(
        calendar: Calendar = .current,
        monthDate: Binding<Date>,
        selection: Binding<Date?>? = nil,
        showsHeader: Bool = true,
        @ViewBuilder dayContent: @escaping (Date) -> DayContent
    ) {
        self.calendar = calendar
        self._monthDate = monthDate
        self.selection = selection
        self.dayContent = dayContent
        self.showsHeader = showsHeader
    }

    public var body: some View {
        VStack(spacing: 16) {
            if showsHeader { header }
            weekdayHeader
            daysGrid
        }
    }

    private var header: some View {
        HStack {
            Button(action: { moveMonth(by: -1) }) {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(monthTitle(for: monthStart))
                .font(.headline)
            Spacer()
            Button(action: { moveMonth(by: 1) }) {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal, 8)
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(weekdaySymbols.indices, id: \.self) { idx in
                Text(weekdaySymbols[idx])
                    .font(.caption)
                    .foregroundStyle(idx == 0 ? .red : (idx == 6 ? .blue : .secondary))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var daysGrid: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(days.indices, id: \.self) { idx in
                if let date = days[idx] {
                    Button {
                        selection?.wrappedValue = date
                    } label: {
                        ZStack {
                            if let sel = selection?.wrappedValue, calendar.isDate(sel, inSameDayAs: date) {
                                RoundedRectangle(cornerRadius: 8).fill(Color.appPlaceholder)
                            }
                            dayContent(date)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(6)
                        }
                        .frame(height: 48)
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear.frame(height: 48)
                }
            }
        }
        .padding(.horizontal, 4)
    }

    private func moveMonth(by delta: Int) {
        if let newDate = calendar.date(byAdding: .month, value: delta, to: monthStart) {
            monthDate = newDate
        }
    }

    private func monthTitle(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale.current
        fmt.dateFormat = DateFormatter.dateFormat(fromTemplate: "yMMMM", options: 0, locale: Locale.current)
        return fmt.string(from: date)
    }
}

public extension CustomCalendar where DayContent == Text {
    init(calendar: Calendar = .current, monthDate: Binding<Date>, selection: Binding<Date?>? = nil, showsHeader: Bool = true) {
        self.init(calendar: calendar, monthDate: monthDate, selection: selection, showsHeader: showsHeader) { date in
            let day = calendar.component(.day, from: date)
            return Text("\(day)")
                .foregroundStyle(Color.appPrimaryText)
        }
    }
}

#Preview {
    struct PreviewHost: View {
        @State var monthDate: Date = .init()
        @State var selection: Date? = nil
        let calendar = Calendar.current
        var body: some View {
            VStack(spacing: 16) {
                CustomCalendar(monthDate: $monthDate, selection: $selection) { date in
                    let day = calendar.component(.day, from: date)
                    // 예시: 주말은 아이콘, 평일은 숫자
                    if calendar.isDateInWeekend(date) {
                        return AnyView(Image(systemName: "book.fill").foregroundStyle(.cyan))
                    } else {
                        return AnyView(Text("\(day)").foregroundStyle(.white))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
            }
        }
    }
    return PreviewHost()
}
