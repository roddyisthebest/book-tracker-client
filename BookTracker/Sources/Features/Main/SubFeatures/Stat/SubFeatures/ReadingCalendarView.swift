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
    @State private var imageSaver = ImageSaver()

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

    @ViewBuilder
    private func dayContentView(for date: Date) -> some View {
        let cal = Calendar.current
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

    private var captureView: some View {
        let year = calendar.component(.year, from: store.date)
        let month = calendar.component(.month, from: store.date)
        return VStack(spacing: 15) {
            HStack {
                Text("reading_tracker")
                    .font(.title3).fontWeight(.bold)
                    .foregroundStyle(Color.appPrimaryText)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 20)

            HStack {
                Text(String(format: String(localized: "month_format %@"), "\(month)"))
                    .font(.title2).fontWeight(.bold).foregroundStyle(Color.appPrimaryText)
                Text("\(year)" + String(localized: "year_suffix"))
                    .font(.title3).fontWeight(.semibold).foregroundStyle(Color.appSecondaryText)
                Spacer()
            }
            .padding(.horizontal)

            CustomCalendar(monthDate: .constant(store.date), selection: .constant(nil), showsHeader: false) { date in
                dayContentView(for: date)
            }
            .padding()
            .padding(.bottom, 20)
        }
        .frame(width: UIScreen.main.bounds.width)
        .background(Color.appBackground)
    }

    private func captureAndSave() {
        let renderer = ImageRenderer(content: captureView)
        renderer.scale = UIScreen.main.scale
        guard let image = renderer.uiImage else {
            store.send(.saveFailed)
            return
        }
        imageSaver.save(image) { success in
            DispatchQueue.main.async {
                if success {
                    store.send(.saveSuccess)
                } else {
                    store.send(.saveFailed)
                }
            }
        }
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

                if store.loadingState == .loading && store.readingRecords == nil {
                    VStack(spacing: 8) {
                        ProgressView().tint(.white)
                        Text("loading")
                            .font(.footnote)
                            .foregroundStyle(Color.appSecondaryText)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .padding()
                } else if store.loadingState == .error {
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
                    CustomCalendar(monthDate: $store.date, selection: .constant(nil), showsHeader: false) { date in
                        dayContentView(for: date)
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
            .navigationTitle("reading_tracker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        captureAndSave()
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .disabled(store.loadingState == .loading || store.loadingState == .error || store.readingRecords == nil)
                }
            }
            .alert(store: store.scope(state: \.$alert, action: \.alert))
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
