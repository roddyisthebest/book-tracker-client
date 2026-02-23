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
                                        if let urlString = store.imageUrl, let url = URL(string: urlString) {
                                            AsyncImage(url: url) { image in
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 100, height: 100)
                                                    .clipShape(Circle())
                                            } placeholder: {
                                                Image(systemName: "person.fill")
                                                    .foregroundStyle(.gray)
                                                    .font(.system(size: 60))
                                            }
                                        } else {
                                            Image(systemName: "person.fill")
                                                .foregroundStyle(.gray)
                                                .font(.system(size: 60))
                                        }

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
                                    StatusRow(key: "이름", value: store.name)
                                    Image(systemName: "chevron.right").foregroundStyle(.gray)
                                }
                            }
                            StatusRow(key: "이메일", value: "bsy17171@naver.com")
                            StatusRow(key: "로그인 수단", value: "apple")

                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 50)

                    }.frame(maxWidth: .infinity, alignment: .leading).padding(.top).padding(.horizontal)
                }
                .padding(.bottom)
            }
        }
        .background(Color(hex: "#101013", default: .black))
    }

    var body: some View {
        mainContent
            .navigationTitle("배성연님의 정보")
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
