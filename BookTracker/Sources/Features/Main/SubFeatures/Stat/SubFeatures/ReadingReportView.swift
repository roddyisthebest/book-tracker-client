//
//  ReadingReportView.swift
//  BookTracker
//
//  Created by 배성연 on 2/21/26.
//

import ComposableArchitecture
import SwiftUI

struct ReadingReportView: View {
    @Bindable var store: StoreOf<ReadingReportFeature>

    private static let decimalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        f.maximumFractionDigits = 0
        return f
    }()

    private func money(_ v: Int) -> String {
        (Self.decimalFormatter.string(from: NSNumber(value: v)) ?? "\(v)") + String(localized: "won_unit")
    }

    private func oneDecimal(_ d: Double) -> String {
        String(format: "%.1f", d)
    }

    private func signedPercent(_ d: Double) -> String {
        if d > 0 { return String(format: "+%.0f%%", d) }
        if d < 0 { return String(format: "%.0f%%", d) }
        return "0%"
    }

    private func changeColor(_ d: Double) -> Color {
        d >= 0 ? .red : .blue
    }

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

    private var emptyReportView: some View {
        VStack(spacing: 14) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 28))
                .foregroundStyle(Color.appSecondaryText)
            Text("no_monthly_report")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.appPrimaryText)
            Text("change_date_or_retry")
                .font(.system(size: 13, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.appSecondaryText)
            Button(action: { store.send(.loadData) }) {
                Text("retry")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: 180)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .foregroundStyle(.black)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, minHeight: 320)
    }

    private var mainContent: some View {
        ScrollView {
            if store.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)
                    Text("loading")
                        .font(.footnote)
                        .foregroundStyle(Color.appSecondaryText)
                }
                .frame(maxWidth: .infinity, minHeight: 320)
            } else if store.monthlyReadingReport == nil && !store.isError {
                emptyReportView
            } else {
                VStack(spacing: 15) {
                    VStack(spacing: 20) {
                        HStack(spacing: 10) {
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

                        HStack(spacing: 10) {
                            Rectangle().fill(Color.appSurface)
                                .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.caption)
                                }
                            StatusRow(key: String(localized: "completed_books"), value: "\((store.monthlyReadingReport?.month.completedCount ?? 0))\(String(localized: "book_unit"))")

                        }.frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 10) {
                            Rectangle().fill(Color.appSurface)
                                .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                    Image(systemName: "xmark.circle.fill").foregroundStyle(.red).font(.caption)
                                }
                            StatusRow(key: String(localized: "unfinished_books"), value: "\((store.monthlyReadingReport?.month.unfinishedCount ?? 0))\(String(localized: "book_unit"))")

                        }.frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 10) {
                            Rectangle().fill(Color.appSurface)
                                .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                    Image(systemName: "star.fill").foregroundStyle(.yellow).font(.caption)
                                }
                            StatusRow(key: String(localized: "average_score"), value: oneDecimal(store.monthlyReadingReport?.month.completedAverageScore ?? 0))

                        }.frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 10) {
                            Rectangle().fill(Color.appSurface)
                                .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                    Image(systemName: "receipt.fill").foregroundStyle(Color.appPurchaseAccent).font(.caption)
                                }
                            StatusRow(key: String(localized: "purchase"), value: "\((store.monthlyReadingReport?.month.purchaseCount ?? 0))\(String(localized: "book_unit"))")

                        }.frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 10) {
                            Rectangle().fill(Color.appSurface)
                                .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                    Image(systemName: "person.text.rectangle.fill").foregroundStyle(Color.appRentalAccent).font(.caption)
                                }
                            StatusRow(key: String(localized: "rental"), value: "\((store.monthlyReadingReport?.month.rentalCount ?? 0))\(String(localized: "book_unit"))")

                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    Rectangle().fill(Color.appSurfaceDeeper).frame(height: 15)

                    VStack(spacing: 20) {
                        HStack {
                            Text("monthly_comparison").font(.title2).fontWeight(.bold).foregroundStyle(Color.appPrimaryText)
                            Spacer()
                        }.padding(.bottom, 5)

                        KeyValueRow {
                            MainLabel("completed_books")
                        } value: {
                            VStack(alignment: .trailing, spacing: 5) {
                                HStack {
                                    Text(String(format: String(localized: "book_count %@"), "\(store.monthlyReadingReport?.comparison.previousCompletedCount ?? 0)"))
                                        .foregroundStyle(Color.appSecondaryText)
                                        .font(.system(size: 18, weight: .bold))
                                        .multilineTextAlignment(.trailing)
                                    Image(systemName: "arrow.right").fontWeight(.semibold)
                                    Text(String(format: String(localized: "book_count %@"), "\(store.monthlyReadingReport?.comparison.currentCompletedCount ?? 0)"))
                                        .foregroundStyle(Color.appPrimaryText)
                                        .font(.system(size: 18, weight: .bold))
                                        .multilineTextAlignment(.trailing)
                                }
                                let delta = store.monthlyReadingReport?.comparison.completedChangePercentage ?? 0
                                if delta != 0 {
                                    Text(signedPercent(delta))
                                        .foregroundStyle(changeColor(delta))
                                        .font(.system(size: 12, weight: .semibold))
                                        .multilineTextAlignment(.trailing)
                                }
                            }
                        }

                        KeyValueRow {
                            MainLabel("unfinished_books")
                        } value: {
                            VStack(alignment: .trailing, spacing: 5) {
                                HStack {
                                    Text(String(format: String(localized: "book_count %@"), "\(store.monthlyReadingReport?.comparison.previousUnfinishedCount ?? 0)"))
                                        .foregroundStyle(Color.appSecondaryText)
                                        .font(.system(size: 18, weight: .bold))
                                        .multilineTextAlignment(.trailing)
                                    Image(systemName: "arrow.right").fontWeight(.semibold)
                                    Text(String(format: String(localized: "book_count %@"), "\(store.monthlyReadingReport?.comparison.currentUnfinishedCount ?? 0)"))
                                        .foregroundStyle(Color.appPrimaryText)
                                        .font(.system(size: 18, weight: .bold))
                                        .multilineTextAlignment(.trailing)
                                }
                                let delta = store.monthlyReadingReport?.comparison.unfinishedChangePercentage ?? 0
                                if delta != 0 {
                                    Text(signedPercent(delta))
                                        .foregroundStyle(changeColor(delta))
                                        .font(.system(size: 12, weight: .semibold))
                                        .multilineTextAlignment(.trailing)
                                }
                            }
                        }

                        KeyValueRow {
                            MainLabel("purchase_amount")
                        } value: {
                            VStack(alignment: .trailing, spacing: 5) {
                                HStack {
                                    Text(money(store.monthlyReadingReport?.comparison.previousPurchaseAmount ?? 0))
                                        .foregroundStyle(Color.appSecondaryText)
                                        .font(.system(size: 18, weight: .bold))
                                        .multilineTextAlignment(.trailing)
                                    Image(systemName: "arrow.right").fontWeight(.semibold)
                                    Text(money(store.monthlyReadingReport?.comparison.currentPurchaseAmount ?? 0))
                                        .foregroundStyle(Color.appPrimaryText)
                                        .font(.system(size: 18, weight: .bold))
                                        .multilineTextAlignment(.trailing)
                                }
                                let delta = store.monthlyReadingReport?.comparison.purchaseAmountChangePercentage ?? 0
                                if delta != 0 {
                                    Text(signedPercent(delta))
                                        .foregroundStyle(changeColor(delta))
                                        .font(.system(size: 12, weight: .semibold))
                                        .multilineTextAlignment(.trailing)
                                }
                            }
                        }

                        KeyValueRow {
                            MainLabel("rental_count")
                        } value: {
                            VStack(alignment: .trailing, spacing: 5) {
                                HStack {
                                    Text(String(format: String(localized: "book_count %@"), "\(store.monthlyReadingReport?.comparison.previousRentalCount ?? 0)"))
                                        .foregroundStyle(Color.appSecondaryText)
                                        .font(.system(size: 18, weight: .bold))
                                        .multilineTextAlignment(.trailing)
                                    Image(systemName: "arrow.right").fontWeight(.semibold)
                                    Text(String(format: String(localized: "book_count %@"), "\(store.monthlyReadingReport?.comparison.currentRentalCount ?? 0)"))
                                        .foregroundStyle(Color.appPrimaryText)
                                        .font(.system(size: 18, weight: .bold))
                                        .multilineTextAlignment(.trailing)
                                }
                                let delta = store.monthlyReadingReport?.comparison.rentalCountChangePercentage ?? 0
                                if delta != 0 {
                                    Text(signedPercent(delta))
                                        .foregroundStyle(changeColor(delta))
                                        .font(.system(size: 12, weight: .semibold))
                                        .multilineTextAlignment(.trailing)
                                }
                            }
                        }
                    }
                    .padding()

                    Rectangle().fill(Color.appSurfaceDeeper).frame(height: 15)

                    VStack(spacing: 20) {
                        HStack {
                            Text("reading_period").font(.title2).fontWeight(.bold).foregroundStyle(Color.appPrimaryText)
                            Spacer()
                        }.padding(.bottom, 5)

                        HStack(spacing: 10) {
                            Rectangle().fill(Color.appSurface)
                                .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                    Image(systemName: "text.page.fill").foregroundStyle(Color(hex: "#72FFD2", default: .accentColor)).font(.caption)
                                }
                            StatusRow(key: String(localized: "avg_reading_days"), value: oneDecimal(store.monthlyReadingReport?.month.averageReadingDays ?? 0) + String(localized: "day_unit"))

                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()

                    Rectangle().fill(Color.appSurfaceDeeper).frame(height: 15)

                    VStack(spacing: 45) {
                        HStack {
                            Text("paper_ebook_ratio").font(.title2).fontWeight(.bold).foregroundStyle(Color.appPrimaryText)
                            Spacer()
                        }.padding(.bottom, 5)

                        DonutChart(
                            segments: [
                                (Color.indigo, store.monthlyReadingReport?.month.ebookPercentage ?? 0.0),
                                (Color.cyan, store.monthlyReadingReport?.month.paperPercentage ?? 0.0)
                            ],
                            lineWidth: 18
                        )
                        .frame(width: 120, height: 120)
                        VStack(spacing: 10) {
                            HStack {
                                Rectangle().fill(.cyan)
                                    .frame(width: 15, height: 15).cornerRadius(5)
                                Text("paper_book").font(.caption)
                                Text("\(String(format: "%.0f%%", store.monthlyReadingReport?.month.paperPercentage ?? 0.0))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                            HStack {
                                Rectangle().fill(.indigo)
                                    .frame(width: 15, height: 15).cornerRadius(5)
                                Text("ebook").font(.caption)
                                Text("\(String(format: "%.0f%%", store.monthlyReadingReport?.month.ebookPercentage ?? 0.0))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                }
            }
        }
        .refreshable {
            store.send(.loadData)
        }
        .overlay(alignment: .top) {
            if store.isError {
                VStack(spacing: 8) {
                    Text("report_load_failed")
                        .font(.footnote)
                        .foregroundStyle(.red.opacity(0.85))
                    Button(action: { store.send(.loadData) }) {
                        Text("retry")
                            .font(.caption)
                    }
                }
                .padding(.top, 8)
            }
        }
        .background(Color.appBackground)
    }

    var body: some View {
        mainContent
            .navigationTitle("reading_report")
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
        ReadingReportView(store: Store(initialState: ReadingReportFeature.State(), reducer: {
            ReadingReportFeature()
        }))
    }
}
