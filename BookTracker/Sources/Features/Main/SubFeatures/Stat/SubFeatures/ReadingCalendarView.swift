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
                        Picker("year", selection: yearBinding) {
                            ForEach(years, id: \.self) { year in
                                (Text(year, format: .number.grouping(.never)) + Text("year_suffix"))
                                    .tag(year)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(3)
                        .tint(Color.appPrimaryText)
                        .background(Color.appSurface)
                        .cornerRadius(10)

                        Picker("month", selection: monthBinding) {
                            ForEach(1...12, id: \.self) { month in
                                Text(String(format: String(localized: "month_format %@"), "\(month)")).tag(month)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(3)
                        .tint(Color.appPrimaryText)
                        .background(Color.appSurface)
                        .cornerRadius(10)
                    }
                }
                .padding()

                if store.isLoading && store.readingRecords == nil {
                    VStack(spacing: 8) {
                        ProgressView().tint(.white)
                        Text("loading")
                            .font(.footnote)
                            .foregroundStyle(Color.appSecondaryText)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .padding()
                } else if store.isError {
                    VStack(spacing: 8) {
                        Text("calendar_load_failed")
                            .font(.footnote)
                            .foregroundStyle(.red.opacity(0.85))
                        Button(action: { store.send(.loadData) }) {
                            Text("retry").font(.caption)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .padding()
                } else {
                    let cal = Calendar.current
                    CustomCalendar(monthDate: $store.date, selection: .constant(nil), showsHeader: false) { date in
                        let day = cal.component(.day, from: date)
                        let key = cal.startOfDay(for: date)
                        let hasRecord = (store.readingRecords?[key] ?? nil) != nil
                        VStack(spacing: 4) {
                            if hasRecord {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.system(size: 16, weight: .bold))
                            } else {
                                Text("\(day)")
                                    .foregroundStyle(Color.appPrimaryText)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
            .frame(maxWidth: .infinity)
        }
        .refreshable {
            store.send(.loadData)
        }
        .background(Color.appBackground)
    }

    var body: some View {
        mainContent
            .navigationTitle("done_reading_calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive, action: {}) {
                            Label("delete_all", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .task { await store.send(.onAppear).finish() }
    }
}

#Preview {
    NavigationStack {
        ReadingCalendarView(store: Store(initialState: ReadingCalendarFeature.State(), reducer: {
            ReadingCalendarFeature()
        }))
    }
}
