//
//  ReadingCalendarView.swift
//  BookTracker
//
//  Created by 배성연 on 2/21/26.
//

import ComposableArchitecture
import SwiftUI

struct ReadingCalendarView: View {
    @Bindable var store: StoreOf<ReadingCalendarFeature>

    private var calendar: Calendar { Calendar.current }
    private var years: [Int] { Array(2000...2026) }

    private var yearBinding: Binding<Int> {
        Binding(
            get: { calendar.component(.year, from: store.date) },
            set: { year in
                var comps = calendar.dateComponents([.year, .month], from: store.date)
                comps.year = year
                comps.day = 1
                if let newDate = calendar.date(from: comps) {
                    $store.date.wrappedValue = newDate
                }
            }
        )
    }

    private var monthBinding: Binding<Int> {
        Binding(
            get: { calendar.component(.month, from: store.date) },
            set: { month in
                var comps = calendar.dateComponents([.year, .month], from: store.date)
                comps.month = month
                comps.day = 1
                if let newDate = calendar.date(from: comps) {
                    $store.date.wrappedValue = newDate
                }
            }
        )
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 15) {
                VStack(spacing: 20) {
                    HStack(alignment: .center, spacing: 10) {
                        Picker("년", selection: yearBinding) {
                            ForEach(years, id: \.self) { year in
                                (Text(year, format: .number.grouping(.never)) + Text("년"))
                                    .tag(year)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(3)
                        .tint(.white)
                        .background(Color(hex: "#2C2C35", default: .white))
                        .cornerRadius(10)

                        Picker("월", selection: monthBinding) {
                            ForEach(1...12, id: \.self) { month in
                                Text("\(month)월").tag(month)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(3)
                        .tint(.white)
                        .background(Color(hex: "#2C2C35", default: .white))
                        .cornerRadius(10)
                    }
                }
                .padding()

                let cal = Calendar.current
                CustomCalendar(monthDate: $store.date, selection: .constant(nil), showsHeader: false) { date in
                    let day = cal.component(.day, from: date)
                    Text("\(day)")
                        .foregroundStyle(.white)
                        .font(.system(size: 16, weight: .semibold))
//                    if cal.isDateInWeekend(date) {
//                        Image(systemName: "book.fill")
//                            .foregroundStyle(.cyan)
//                            .font(.system(size: 14, weight: .semibold))
//                    } else {
//                        Text("\(day)")
//                            .foregroundStyle(.white)
//                            .font(.system(size: 14, weight: .semibold))
//                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .frame(maxWidth: .infinity)
        }
        .background(Color(hex: "#101013", default: .black))
    }

    var body: some View {
        mainContent
            .navigationTitle("완독 독서 캘린더")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive, action: {}) {
                            Label("전체 삭제", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
    }
}

#Preview {
    NavigationStack {
        ReadingCalendarView(store: Store(initialState: ReadingCalendarFeature.State(), reducer: {
            ReadingCalendarFeature()
        }))
    }
}
