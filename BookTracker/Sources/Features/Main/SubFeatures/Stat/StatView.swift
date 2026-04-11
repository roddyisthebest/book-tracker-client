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
                                Text("reading_report").font(.title2).fontWeight(.bold).foregroundStyle(Color.appPrimaryText)
                                Spacer()
                            }
                            Text("reading_report_description").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.appSecondaryText)
                        }
                        Image(systemName: "chevron.right").fontWeight(.semibold).foregroundStyle(Color.appSecondaryText).font(.system(size: 16))

                    }.padding()
                }

                Rectangle().fill(Color.appSurfaceDeeper).frame(height: 15)

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("my_reading_record").font(.title2).fontWeight(.bold).foregroundStyle(Color.appPrimaryText).lineLimit(1)
                        Text("reading_report_description").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.appSecondaryText).lineLimit(1)

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
                                        Text("done_reading_calendar").font(.title3).fontWeight(.bold).foregroundStyle(Color.appPrimaryText)
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
                                        Text("reading_tracker").font(.title3).fontWeight(.bold).foregroundStyle(Color.appPrimaryText)
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

        .navigationTitle("statistics")
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
