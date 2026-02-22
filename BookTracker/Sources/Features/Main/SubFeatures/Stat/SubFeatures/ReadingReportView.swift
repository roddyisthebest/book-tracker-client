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
                        StatusRow(key: "완독한 책", value: "3권")

                    }.frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 10) {
                        Rectangle().fill(Color(hex: "#2C2C35", default: .black))
                            .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(.red).font(.caption)
                            }
                        StatusRow(key: "읽다 만 책", value: "103권")

                    }.frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 10) {
                        Rectangle().fill(Color(hex: "#2C2C35", default: .black))
                            .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                Image(systemName: "star.fill").foregroundStyle(.yellow).font(.caption)
                            }
                        StatusRow(key: "평균 별점", value: "4.2")

                    }.frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 10) {
                        Rectangle().fill(Color(hex: "#2C2C35", default: .black))
                            .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                Image(systemName: "receipt.fill").foregroundStyle(Color(hex: "#67E9AF", default: .white)).font(.caption)
                            }
                        StatusRow(key: "구매", value: "0권")

                    }.frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 10) {
                        Rectangle().fill(Color(hex: "#2C2C35", default: .black))
                            .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                Image(systemName: "person.text.rectangle.fill").foregroundStyle(Color(hex: "#7D7DFF", default: .white)).font(.caption)
                            }
                        StatusRow(key: "대여", value: "0권")

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
                                Text("2권")
                                    .foregroundStyle(.white.opacity(0.35))
                                    .font(.system(size: 18, weight: .bold))
                                    .multilineTextAlignment(.trailing)
                                Image(systemName: "arrow.right").fontWeight(.semibold)
                                Text("3권")
                                    .foregroundStyle(.white.opacity(0.85))
                                    .font(.system(size: 18, weight: .bold))
                                    .multilineTextAlignment(.trailing)
                            }
                            Text("-33%")
                                .foregroundStyle(.blue)
                                .font(.system(size: 12, weight: .semibold))
                                .multilineTextAlignment(.trailing)
                        }
                    }

                    KeyValueRow {
                        MainLabel("읽다 만 책")
                    } value: {
                        VStack(alignment: .trailing, spacing: 5) {
                            HStack {
                                Text("2권")
                                    .foregroundStyle(.white.opacity(0.35))
                                    .font(.system(size: 18, weight: .bold))
                                    .multilineTextAlignment(.trailing)
                                Image(systemName: "arrow.right").fontWeight(.semibold)
                                Text("3권")
                                    .foregroundStyle(.white.opacity(0.85))
                                    .font(.system(size: 18, weight: .bold))
                                    .multilineTextAlignment(.trailing)
                            }
                            Text("-33%")
                                .foregroundStyle(.blue)
                                .font(.system(size: 12, weight: .semibold))
                                .multilineTextAlignment(.trailing)
                        }
                    }

                    KeyValueRow {
                        MainLabel("구매 금액")
                    } value: {
                        VStack(alignment: .trailing, spacing: 5) {
                            HStack {
                                Text("48,000원")
                                    .foregroundStyle(.white.opacity(0.35))
                                    .font(.system(size: 18, weight: .bold))
                                    .multilineTextAlignment(.trailing)
                                Image(systemName: "arrow.right").fontWeight(.semibold)
                                Text("0원")
                                    .foregroundStyle(.white.opacity(0.85))
                                    .font(.system(size: 18, weight: .bold))
                                    .multilineTextAlignment(.trailing)
                            }
                            Text("-100%")
                                .foregroundStyle(.blue)
                                .font(.system(size: 12, weight: .semibold))
                                .multilineTextAlignment(.trailing)
                        }
                    }

                    KeyValueRow {
                        MainLabel("대여권 수")
                    } value: {
                        VStack(alignment: .trailing, spacing: 5) {
                            HStack {
                                Text("3권")
                                    .foregroundStyle(.white.opacity(0.35))
                                    .font(.system(size: 18, weight: .bold))
                                    .multilineTextAlignment(.trailing)
                                Image(systemName: "arrow.right").fontWeight(.semibold)
                                Text("4권")
                                    .foregroundStyle(.white.opacity(0.85))
                                    .font(.system(size: 18, weight: .bold))
                                    .multilineTextAlignment(.trailing)
                            }
                            Text("+33%")
                                .foregroundStyle(.red)
                                .font(.system(size: 12, weight: .semibold))
                                .multilineTextAlignment(.trailing)
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
                        StatusRow(key: "한권당 평균 독서 기간", value: "3권")

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
                            (Color.indigo, 40),
                            (Color.cyan, 60)
                        ],
                        lineWidth: 18
                    )
                    .frame(width: 120, height: 120)
                    VStack(spacing: 10) {
                        HStack {
                            Rectangle().fill(.cyan)
                                .frame(width: 15, height: 15).cornerRadius(5)
                            Text("종이책").font(.caption)
                            Text("60%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        HStack {
                            Rectangle().fill(.indigo)
                                .frame(width: 15, height: 15).cornerRadius(5)
                            Text("전자책").font(.caption)
                            Text("40%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
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
    }
}

#Preview {
    NavigationStack {
        ReadingReportView(store: Store(initialState: ReadingReportFeature.State(), reducer: {
            ReadingReportFeature()
        }))
    }
}
