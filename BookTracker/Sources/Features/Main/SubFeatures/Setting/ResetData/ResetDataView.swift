//
//  ResetDataView.swift
//  BookTracker
//
//  Created by 배성연 on 4/25/26.
//

import ComposableArchitecture
import SwiftUI

struct ResetDataView: View {
    @Bindable var store: StoreOf<ResetDataFeature>

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 15) {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("app_data_reset").font(.title2).fontWeight(.bold).lineLimit(1)
                        Text("app_data_reset_description").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.appSecondaryText)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                Rectangle().fill(Color.appSurface)
                                    .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                        Image(systemName: "internaldrive.fill").foregroundStyle(.orange).font(.system(size: 14))
                                    }

                                Text("app_data_reset_title").font(.title3).fontWeight(.bold).foregroundStyle(Color.appPrimaryText)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Label("search_history", systemImage: "circle.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.appSecondaryText)
                                    .labelStyle(BulletLabelStyle())

                                Label("receipt_temp_data", systemImage: "circle.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.appSecondaryText)
                                    .labelStyle(BulletLabelStyle())
                            }.padding(.leading, 40)

                            Button(action: {
                                store.send(.deleteAppDataTapped)
                            }) {
                                HStack {
                                    Spacer()
                                    if store.isAppDataDeleting {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text("delete_app_data").fontWeight(.bold)
                                    }
                                    Spacer()
                                }
                                .foregroundStyle(.white)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.orange)
                                )
                            }
                            .disabled(store.isAppDataDeleting)
                            .padding(.top, 4)

                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 20)

                    }.frame(maxWidth: .infinity, alignment: .leading).padding(.top).padding(.horizontal)
                }
                .padding(.bottom)

                Rectangle().fill(Color.appSurfaceDeeper).frame(height: 15)

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("server_data_reset").font(.title2).fontWeight(.bold).lineLimit(1)
                        Text("server_data_reset_description").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.appSecondaryText)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                Rectangle().fill(Color.appSurface)
                                    .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                        Image(systemName: "cloud.fill").foregroundStyle(.red).font(.system(size: 14))
                                    }

                                Text("server_data_reset_title").font(.title3).fontWeight(.bold).foregroundStyle(Color.appPrimaryText)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Label("registered_books", systemImage: "circle.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.appSecondaryText)
                                    .labelStyle(BulletLabelStyle())

                                Label("collections", systemImage: "circle.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.appSecondaryText)
                                    .labelStyle(BulletLabelStyle())

                                Label("reading_records", systemImage: "circle.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.appSecondaryText)
                                    .labelStyle(BulletLabelStyle())

                                Label("receipts", systemImage: "circle.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.appSecondaryText)
                                    .labelStyle(BulletLabelStyle())
                            }.padding(.leading, 40)

                            Button(action: {
                                store.send(.deleteServerDataTapped)
                            }) {
                                HStack {
                                    Spacer()
                                    if store.isServerDataDeleting {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text("delete_server_data").fontWeight(.bold)
                                    }
                                    Spacer()
                                }
                                .foregroundStyle(.white)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red)
                                )
                            }
                            .disabled(store.isServerDataDeleting)
                            .padding(.top, 4)

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
            .navigationTitle("data_reset")
            .navigationBarTitleDisplayMode(.inline)
            .alert(store: store.scope(state: \.$alert, action: \.alert))
    }
}

private struct BulletLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center, spacing: 8) {
            configuration.icon
                .font(.system(size: 4))
            configuration.title
        }
    }
}

#Preview {
    NavigationStack {
        ResetDataView(store: Store(initialState: ResetDataFeature.State(), reducer: {
            ResetDataFeature()
        }))
    }
}
