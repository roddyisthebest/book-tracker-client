//
//  DataManageView.swift
//  BookTracker
//
//  Created by 배성연 on 2/22/26.
//

import ComposableArchitecture
import SwiftUI

struct DataManageView: View {
    let store: StoreOf<DataManageFeature>

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 15) {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("file_export").font(.title2).fontWeight(.bold).lineLimit(1)
                        Text("file_export_description").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.appSecondaryText).lineLimit(1)

                        VStack(spacing: 18) {
                            Button(action: {
                                store.send(.csvExportButtonTapped)
                            }) {
                                HStack(spacing: 10) {
                                    Rectangle().fill(Color.appSurface)
                                        .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                            Image(systemName: "square.and.arrow.up.fill").foregroundStyle(Color.appPrimaryText).font(.system(size: 12))
                                        }

                                    HStack {
                                        Text("csv_export").font(.title3).fontWeight(.bold).foregroundStyle(Color.appPrimaryText)
                                        Spacer()
                                        Image(systemName: "chevron.right").fontWeight(.semibold).foregroundStyle(Color.appSecondaryText).font(.system(size: 16))
                                    }
                                }
                            }

                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 20)

                    }.frame(maxWidth: .infinity, alignment: .leading).padding(.top).padding(.horizontal)
                }
                .padding(.bottom)

                Rectangle().fill(Color.appSurfaceDeeper).frame(height: 15)

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("reset").font(.title2).fontWeight(.bold).lineLimit(1)
                        Text("reset_description").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.appSecondaryText).lineLimit(1)

                        VStack(spacing: 18) {
                            Button(action: {
                                store.send(.dataResetButtonTapped)
                            }) {
                                HStack(spacing: 10) {
                                    Rectangle().fill(Color.appSurface)
                                        .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                            Image(systemName: "trash").foregroundStyle(.red).font(.system(size: 12))
                                        }

                                    HStack {
                                        Text("data_reset").font(.title3).fontWeight(.bold).foregroundStyle(Color.appPrimaryText)
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

    var body: some View {
        mainContent
            .navigationTitle("data_management")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: Binding(
                get: { store.isSharePresented },
                set: { presented in
                    if !presented { store.send(.shareDismissed) }
                }
            )) {
                if let path = store.exportFilePath {
                    ShareView(url: URL(fileURLWithPath: path)) {
                        store.send(.shareDismissed)
                    }
                } else {
                    VStack { Text("no_file") }
                        .onDisappear { store.send(.shareDismissed) }
                }
            }
    }
}

#Preview {
    NavigationStack {
        DataManageView(store: Store(initialState: DataManageFeature.State(), reducer: {
            DataManageFeature()
        }))
    }
}
