//
//  StatView.swift
//  BookTracker
//
//  Created by 배성연 on 2/21/26.
//

import ComposableArchitecture
import SwiftUI

struct StatView: View {
    @Bindable var store: StoreOf<StatFeature>

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 15) {
                Button(action: {
                    store.send(.navigateButtonTapped(.readingReport))
                }) {
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Rectangle().fill(Color.appSurface)
                                    .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                        Image(systemName: "text.page.fill").foregroundStyle(Color(hex: "#72FFD2", default: .accentColor)).font(.caption)
                                    }
                                Text("독서 리포트").font(.title2).fontWeight(.bold).foregroundStyle(Color.appPrimaryText)
                                Spacer()
                            }
                            Text("독서 통계와 그래프로 나의 독서 패턴을 분석해보세요").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.appSecondaryText)
                        }
                        Image(systemName: "chevron.right").fontWeight(.semibold).foregroundStyle(Color.appSecondaryText).font(.system(size: 16))

                    }.padding()
                }

                Rectangle().fill(Color.appSurfaceDeeper).frame(height: 15)

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("나의 독서 기록").font(.title2).fontWeight(.bold).foregroundStyle(Color.appPrimaryText).lineLimit(1)
                        Text("독서 통계와 그래프로 나의 독서 패턴을 분석해보세요").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.appSecondaryText).lineLimit(1)

                        VStack(spacing: 18) {
                            Button(action: {
                                store.send(.navigateButtonTapped(.doneBookCalandar))

                            }) {
                                HStack(spacing: 10) {
                                    Rectangle().fill(Color.appSurface)
                                        .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                            Image(systemName: "calendar").foregroundStyle(.blue)
                                        }

                                    HStack {
                                        Text("완독 독서 캘린더").font(.title3).fontWeight(.bold).foregroundStyle(Color.appPrimaryText)
                                        Spacer()
                                        Image(systemName: "chevron.right").fontWeight(.semibold).foregroundStyle(Color.appSecondaryText).font(.system(size: 16))
                                    }
                                }
                            }

                            Button(action: {
                                store.send(.navigateButtonTapped(.readingTrakcer))
                            }) {
                                HStack(spacing: 10) {
                                    Rectangle().fill(Color.appSurface)
                                        .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                        }

                                    HStack {
                                        Text("독서 트래커").font(.title3).fontWeight(.bold).foregroundStyle(Color.appPrimaryText)
                                        Spacer()
                                        Image(systemName: "chevron.right").fontWeight(.semibold).foregroundStyle(Color.appSecondaryText).font(.system(size: 16))
                                    }
                                }
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 20)

                    }.frame(maxWidth: .infinity, alignment: .leading).padding(.top).padding(.horizontal)
                }
                .padding(.bottom)
            }
        }
        .background(Color.appBackground)
    }

    @ViewBuilder
    private func destinationView(for destinationStore: StoreOf<StatFeature.Path>) -> some View {
        switch destinationStore.state {
        case .readingCalendar:
            if let store = destinationStore.scope(state: \.readingCalendar, action: \.readingCalendar) {
                ReadingCalendarView(store: store)
            }
        case .readingReport:
            if let store = destinationStore.scope(state: \.readingReport, action: \.readingReport) {
                ReadingReportView(store: store)
            }
        case .doneBookCalandar:
            if let store = destinationStore.scope(state: \.doneBookCalandar, action: \.doneBookCalendar) {
                DoneBooksCalendarView(store: store)
            }
        }
    }

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            mainContent
        } destination: { destinationStore in
            destinationView(for: destinationStore)
        }

        .navigationTitle("통계")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        StatView(store: Store(initialState: StatFeature.State(), reducer: {
            StatFeature()
        }))
    }
}
