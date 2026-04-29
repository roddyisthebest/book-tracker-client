//
//  MyInfoView.swift
//  BookTracker
//
//  Created by 배성연 on 2/22/26.
//

import ComposableArchitecture
import Foundation
import Kingfisher
import SwiftUI

struct MyInfoView: View {
    @Bindable var store: StoreOf<MyInfoFeature>

    @ViewBuilder
    private func skeletonStatusRow(width: CGFloat) -> some View {
        HStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.appSurface)
                .frame(width: width, height: 18)

            Spacer()

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.appSurface)
                .frame(width: width, height: 18)
        }
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 15) {
                VStack(spacing: 20) {
                    VStack(alignment: .center, spacing: 5) {
                        Button(action: {
                            store.send(.profileImageViewTapped)
                        }) {
                            Rectangle().fill(Color.appSurface)
                                .frame(width: 100, height: 100).cornerRadius(50).overlay {
                                    ZStack {
                                        if store.isUpdatingImage {
                                            ProgressView()
                                                .tint(.gray)
                                        } else if let url = store.profile?.profileImageURL {
                                            KFImage(url)
                                                .placeholder {
                                                    ProgressView().tint(.gray)
                                                }
                                                .retry(maxCount: 2, interval: .seconds(1))
                                                .fade(duration: 0.2)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .clipShape(Circle())
                                        } else {
                                            Image(systemName: "person.fill")
                                                .foregroundStyle(.gray)
                                                .font(.system(size: 60))
                                        }
                                        ZStack {
                                            Circle()
                                                .fill(Color.appSurface)
                                                .frame(width: 25, height: 25)
                                            Image(systemName: "dice.fill")
                                                .font(.system(size: 15))
                                                .foregroundStyle(Color.accentColor)
                                        }
                                        .opacity(0.4)
                                    }
                                }
                        }
                        .disabled(store.isUpdatingImage)

                        VStack(spacing: 25) {
                            Button(action: {
                                store.send(.nameEditButtonTapped)
                            }) {
                                HStack(spacing: 10) {
                                    StatusRow(key: String(localized: "name_label"), value: store.profile?.name ?? "unknown")
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.gray)
                                }
                            }

                            if let authInfo = store.authInfo, let email = authInfo.email, let provider = authInfo.provider {
                                StatusRow(key: String(localized: "email_label"), value: email)
                                StatusRow(key: String(localized: "login_method"), value: provider)
                            } else {
                                VStack(spacing: 25) {
                                    skeletonStatusRow(width: 80)
                                    skeletonStatusRow(width: 80)
                                }
                                .redacted(reason: .placeholder)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 50)

                    }.frame(maxWidth: .infinity, alignment: .leading).padding(.top).padding(.horizontal)
                }
                .padding(.bottom)
            }
        }
        .background(Color.appBackground)
    }

    var body: some View {
        mainContent
            .navigationTitle("my_info")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(store: store.scope(state: \.$destination.updateName, action: \.destination.updateName)) {
                updateNameStore in
                UpdateNameView(store: updateNameStore)
            }
    }
}

#Preview {
    NavigationStack {
        MyInfoView(store: Store(initialState: MyInfoFeature.State(), reducer: {
            MyInfoFeature()
        }))
    }
}
