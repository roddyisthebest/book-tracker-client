//
//  MyInfoView.swift
//  BookTracker
//
//  Created by 배성연 on 2/22/26.
//

import ComposableArchitecture
import Foundation
import SwiftUI

struct MyInfoView: View {
    @Bindable var store: StoreOf<MyInfoFeature>

    @ViewBuilder
    private func skeletonStatusRow(width: CGFloat) -> some View {
        HStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: "#2C2C35", default: .black))
                .frame(width: width, height: 18)

            Spacer()

            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: "#2C2C35", default: .black))
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
                            Rectangle().fill(Color(hex: "#2C2C35", default: .black))
                                .frame(width: 100, height: 100).cornerRadius(50).overlay {
                                    ZStack(alignment: .bottomTrailing) {
//                                        if let urlString = store.profile, let url = URL(string: urlString) {
//                                            AsyncImage(url: url) { image in
//                                                image
//                                                    .resizable()
//                                                    .scaledToFill()
//                                                    .frame(width: 100, height: 100)
//                                                    .clipShape(Circle())
//                                            } placeholder: {
//                                                Image(systemName: "person.fill")
//                                                    .foregroundStyle(.gray)
//                                                    .font(.system(size: 60))
//                                            }
//                                        } else {
//                                            Image(systemName: "person.fill")
//                                                .foregroundStyle(.gray)
//                                                .font(.system(size: 60))
//                                        }
                                        Image(systemName: "person.fill")
                                            .foregroundStyle(.gray)
                                            .font(.system(size: 60))
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: "#2C2C35", default: .black))
                                                .frame(width: 25, height: 25)
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 22))
                                        }
                                        .offset(x: 15, y: 15)
                                    }
                                }
                        }

                        VStack(spacing: 25) {
                            Button(action: {
                                store.send(.nameEditButtonTapped)
                            }) {
                                HStack(spacing: 10) {
                                    StatusRow(key: "이름", value: store.profile?.name ?? "unknown")
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.gray)
                                }
                            }

                            if store.isFetching {
                                VStack(spacing: 25) {
                                    skeletonStatusRow(width: 80)
                                    skeletonStatusRow(width: 80)
                                }
                                .redacted(reason: .placeholder)

                            } else if store.isError {
                                VStack(alignment: .leading, spacing: 14) {
                                    Text("계정 정보를 불러오지 못했어요")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.white)

                                    Button(action: {
                                        store.send(.onRefresh)
                                    }) {
                                        Text("다시 시도")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color(hex: "#2C2C35", default: .black))
                                            )
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                            } else if let authInfo = store.myAuthInfo, let email = authInfo.email, let provider = authInfo.provider {
                                StatusRow(key: "이메일", value: email)
                                StatusRow(key: "로그인 수단", value: provider)
                            } else {
                                VStack(alignment: .leading, spacing: 14) {
                                    Text("계정 정보가 없어요")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.white)

                                    Button(action: {
                                        store.send(.onRefresh)
                                    }) {
                                        Text("새로고침")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color(hex: "#2C2C35", default: .black))
                                            )
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 50)

                    }.frame(maxWidth: .infinity, alignment: .leading).padding(.top).padding(.horizontal)
                }
                .padding(.bottom)
            }
        }
        .background(Color(hex: "#101013", default: .black))
    }

    var body: some View {
        mainContent
            .navigationTitle("내 정보")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(store: store.scope(state: \.$destination.updateName, action: \.destination.updateName)) {
                updateNameStore in
                UpdateNameView(store: updateNameStore)
            }
            .onAppear { store.send(.onAppear) }
    }
}

#Preview {
    NavigationStack {
        MyInfoView(store: Store(initialState: MyInfoFeature.State(profile: MyProfile(id: UUID(), name: "asdd", role: "as", phoneToken: "21312323", createdAt: Date(), deletedAt: Date())), reducer: {
            MyInfoFeature()
        }))
    }
}
