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
        (Self.decimalFormatter.string(from: NSNumber(value: v)) ?? "\(v)") + "원"
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
                .foregroundStyle(.white.opacity(0.8))
            Text("이 달의 리포트가 없어요")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
            Text("연/월을 바꾸거나 다시 시도해 보세요.")
                .font(.system(size: 13, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.6))
            Button(action: { store.send(.loadData) }) {
                Text("다시 시도")
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
                    Text("불러오는 중…")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, minHeight: 320)
            } else if store.monthlyReadingReport == nil && !store.isError {
                emptyReportView
            } else {
                VStack(spacing: 15) {
                    VStack(spacing: 20) {
                        HStack(spacing: 10) {
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

                        HStack(spacing: 10) {
                            Rectangle().fill(Color(hex: "#2C2C35", default: .black))
                                .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.caption)
                                }
                            StatusRow(key: "완독한 책", value: "\((store.monthlyReadingReport?.month.completedCount ?? 0))권")

                        }.frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 10) {
                            Rectangle().fill(Color(hex: "#2C2C35", default: .black))
                                .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                    Image(systemName: "xmark.circle.fill").foregroundStyle(.red).font(.caption)
                                }
                            StatusRow(key: "읽다 만 책", value: "\((store.monthlyReadingReport?.month.unfinishedCount ?? 0))권")

                        }.frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 10) {
                            Rectangle().fill(Color(hex: "#2C2C35", default: .black))
                                .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                    Image(systemName: "star.fill").foregroundStyle(.yellow).font(.caption)
                                }
                            StatusRow(key: "평균 별점", value: oneDecimal(store.monthlyReadingReport?.month.completedAverageScore ?? 0))

                        }.frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 10) {
                            Rectangle().fill(Color(hex: "#2C2C35", default: .black))
                                .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                    Image(systemName: "receipt.fill").foregroundStyle(Color(hex: "#67E9AF", default: .white)).font(.caption)
                                }
                            StatusRow(key: "구매", value: "\((store.monthlyReadingReport?.month.purchaseCount ?? 0))권")

                        }.frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 10) {
                            Rectangle().fill(Color(hex: "#2C2C35", default: .black))
                                .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                    Image(systemName: "person.text.rectangle.fill").foregroundStyle(Color(hex: "#7D7DFF", default: .white)).font(.caption)
                                }
                            StatusRow(key: "대여", value: "\((store.monthlyReadingReport?.month.rentalCount ?? 0))권")

                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    Divider().frame(height: 15).background(.black)

                    VStack(spacing: 20) {
                        HStack {
                            Text("전월 비교").font(.title2).fontWeight(.bold)
                            Spacer()
                        }.padding(.bottom, 5)

                        KeyValueRow {
                            MainLabel("완독한 책")
                        } value: {
                            VStack(alignment: .trailing, spacing: 5) {
                                HStack {
                                    Text("\(store.monthlyReadingReport?.comparison.previousCompletedCount ?? 0)권")
                                        .foregroundStyle(.white.opacity(0.35))
                                        .font(.system(size: 18, weight: .bold))
                                        .multilineTextAlignment(.trailing)
                                    Image(systemName: "arrow.right").fontWeight(.semibold)
                                    Text("\(store.monthlyReadingReport?.comparison.currentCompletedCount ?? 0)권")
                                        .foregroundStyle(.white.opacity(0.85))
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
                            MainLabel("읽다 만 책")
                        } value: {
                            VStack(alignment: .trailing, spacing: 5) {
                                HStack {
                                    Text("\(store.monthlyReadingReport?.comparison.previousUnfinishedCount ?? 0)권")
                                        .foregroundStyle(.white.opacity(0.35))
                                        .font(.system(size: 18, weight: .bold))
                                        .multilineTextAlignment(.trailing)
                                    Image(systemName: "arrow.right").fontWeight(.semibold)
                                    Text("\(store.monthlyReadingReport?.comparison.currentUnfinishedCount ?? 0)권")
                                        .foregroundStyle(.white.opacity(0.85))
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
                            MainLabel("구매 금액")
                        } value: {
                            VStack(alignment: .trailing, spacing: 5) {
                                HStack {
                                    Text(money(store.monthlyReadingReport?.comparison.previousPurchaseAmount ?? 0))
                                        .foregroundStyle(.white.opacity(0.35))
                                        .font(.system(size: 18, weight: .bold))
                                        .multilineTextAlignment(.trailing)
                                    Image(systemName: "arrow.right").fontWeight(.semibold)
                                    Text(money(store.monthlyReadingReport?.comparison.currentPurchaseAmount ?? 0))
                                        .foregroundStyle(.white.opacity(0.85))
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
                            MainLabel("대여권 수")
                        } value: {
                            VStack(alignment: .trailing, spacing: 5) {
                                HStack {
                                    Text("\(store.monthlyReadingReport?.comparison.previousRentalCount ?? 0)권")
                                        .foregroundStyle(.white.opacity(0.35))
                                        .font(.system(size: 18, weight: .bold))
                                        .multilineTextAlignment(.trailing)
                                    Image(systemName: "arrow.right").fontWeight(.semibold)
                                    Text("\(store.monthlyReadingReport?.comparison.currentRentalCount ?? 0)권")
                                        .foregroundStyle(.white.opacity(0.85))
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

                    Divider().frame(height: 15).background(.black)

                    VStack(spacing: 20) {
                        HStack {
                            Text("독서기간").font(.title2).fontWeight(.bold)
                            Spacer()
                        }.padding(.bottom, 5)

                        HStack(spacing: 10) {
                            Rectangle().fill(Color(hex: "#2C2C35", default: .black))
                                .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                    Image(systemName: "text.page.fill").foregroundStyle(Color(hex: "#72FFD2", default: .accentColor)).font(.caption)
                                }
                            StatusRow(key: "한권당 평균 독서 기간", value: oneDecimal(store.monthlyReadingReport?.month.averageReadingDays ?? 0) + "일")

                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()

                    Divider().frame(height: 15).background(.black)

                    VStack(spacing: 45) {
                        HStack {
                            Text("종이책/전자책 비율").font(.title2).fontWeight(.bold)
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
                                Text("종이책").font(.caption)
                                Text("\(String(format: "%.0f%%", store.monthlyReadingReport?.month.paperPercentage ?? 0.0))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                            HStack {
                                Rectangle().fill(.indigo)
                                    .frame(width: 15, height: 15).cornerRadius(5)
                                Text("전자책").font(.caption)
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
                    Text("리포트를 불러오지 못했어요")
                        .font(.footnote)
                        .foregroundStyle(.red.opacity(0.85))
                    Button(action: { store.send(.loadData) }) {
                        Text("다시 가져오기")
                            .font(.caption)
                    }
                }
                .padding(.top, 8)
            }
        }
        .background(Color(hex: "#101013", default: .black))
    }

    var body: some View {
        mainContent
            .navigationTitle("독서 리포트")
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
