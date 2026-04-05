import ComposableArchitecture
import SwiftUI

struct DoneBooksCalendarView: View {
    @Bindable var store: StoreOf<DoneBooksCalendarFeature>

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

    var body: some View {
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

                if store.isLoading && store.thumbnailsByDate == nil {
                    VStack(spacing: 8) {
                        ProgressView().tint(.white)
                        Text("불러오는 중…")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .padding()
                } else if store.isError {
                    VStack(spacing: 8) {
                        Text("달력을 불러오지 못했어요")
                            .font(.footnote)
                            .foregroundStyle(.red.opacity(0.85))
                        Button(action: { store.send(.loadData) }) {
                            Text("다시 가져오기").font(.caption)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .padding()
                } else {
                    let cal = Calendar.current
                    CustomCalendar(monthDate: $store.date, selection: .constant(nil), showsHeader: false) { date in
                        let key = cal.startOfDay(for: date)
                        let items = store.thumbnailsByDate?[key] ?? []
                        if items.isEmpty {
                            Text("\(cal.component(.day, from: date))")
                                .foregroundStyle(.white)
                                .font(.system(size: 16, weight: .semibold))
                        } else {
                            DoneBookThumbnailsGrid(items: Array(items.prefix(4)))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
            .frame(maxWidth: .infinity)
        }
        .refreshable { store.send(.loadData) }
        .background(Color(hex: "#101013", default: .black))
        .navigationTitle("완독 독서 캘린더")
        .navigationBarTitleDisplayMode(.inline)
        .task { await store.send(.onAppear).finish() }
    }
}

#Preview {
    NavigationStack {
        DoneBooksCalendarView(store: Store(initialState: DoneBooksCalendarFeature.State(), reducer: { DoneBooksCalendarFeature() }))
    }
}
