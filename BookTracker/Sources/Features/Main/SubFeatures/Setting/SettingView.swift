//
//  SettingView.swift
//  BookTracker
//
//  Created by 배성연 on 2/22/26.
//

import ComposableArchitecture
import SwiftUI

struct SettingView: View {
    @Bindable var store: StoreOf<SettingFeature>

    private var mainContent: some View {
        ScrollView {
            Button(action: {
                store.send(.navigateButtonTapped(.myInfo))
            }) {
                if store.isFetching {
                    HStack {
                        Circle()
                            .fill(Color(hex: "#33353D", default: .gray))
                            .frame(width: 60, height: 60)

                        VStack(alignment: .leading, spacing: 6) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: "#33353D", default: .gray))
                                .frame(width: 120, height: 20)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: "#33353D", default: .gray))
                                .frame(width: 80, height: 16)
                        }

                        Spacer()
                    }
                    .padding(.horizontal)
                    .redacted(reason: .placeholder)

                } else if store.isError {
                    VStack(spacing: 10) {
                        Text("프로필을 불러오지 못했어요")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)

                        Button {
                            store.send(.onRefresh)
                        } label: {
                            Text("다시 시도")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(hex: "#33353D", default: .gray))
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)

                } else if let profile = store.profile {
                    HStack {
                        Circle()
                            .fill(Color(hex: "#33353D", default: .gray))
                            .frame(width: 60, height: 60)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(.gray)
                                    .font(.system(size: 30))
                            }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(profile.name ?? "unknown")
                                .font(.title2)
                                .fontWeight(.bold)
                                .lineLimit(1)
                                .foregroundStyle(.white)

                            Text("내 정보 관리")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color(hex: "#7E7E87", default: .gray))
                                .lineLimit(1)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 16))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color(hex: "#62626D", default: .gray))
                    }
                    .padding(.horizontal)

                } else {
                    VStack(spacing: 10) {
                        Text("프로필 정보가 없어요")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)

                        Button {
                            store.send(.onRefresh)
                        } label: {
                            Text("새로고침")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(hex: "#33353D", default: .gray))
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                }

            }.padding(.bottom, 10)

            VStack(spacing: 15) {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("앱 데이터").font(.title2).fontWeight(.bold).lineLimit(1)
                        Text("내 데이터를 안전하게 보관하고 관리하세요").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color(hex: "#7E7E87", default: .gray)).lineLimit(1)

                        VStack(spacing: 18) {
                            Button(action: {
                                store.send(.navigateButtonTapped(.dataManage))
                            }) {
                                HStack(spacing: 10) {
                                    Rectangle().fill(Color(hex: "#2C2C35", default: .black))
                                        .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                            Image(systemName: "externaldrive.fill").foregroundStyle(.cyan).font(.system(size: 15))
                                        }

                                    HStack {
                                        Text("데이터 관리").font(.title3).fontWeight(.bold).foregroundStyle(.white)
                                        Spacer()
                                        Image(systemName: "chevron.right").fontWeight(.semibold).foregroundStyle(Color(hex: "#62626D", default: .gray)).font(.system(size: 16))
                                    }
                                }
                            }

                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 20)

                    }.frame(maxWidth: .infinity, alignment: .leading).padding(.top).padding(.horizontal)
                }
                .padding(.bottom)
                .padding(.top, 10)

                Divider().frame(height: 15).background(.black)

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("앱 사용").font(.title2).fontWeight(.bold).lineLimit(1)
                        Text("자주 묻는 질문과 해결 방법을 빠르게 찾아보세요").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color(hex: "#7E7E87", default: .gray)).lineLimit(1)

                        VStack(spacing: 18) {
                            Button(action: {}) {
                                HStack(spacing: 10) {
                                    Rectangle().fill(Color(hex: "#2C2C35", default: .black))
                                        .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                            Image(systemName: "questionmark.app.fill").foregroundStyle(.blue).font(.system(size: 16))
                                        }

                                    HStack {
                                        Text("사용 가이드").font(.title3).fontWeight(.bold).foregroundStyle(.white)
                                        Spacer()
                                        Image(systemName: "chevron.right").fontWeight(.semibold).foregroundStyle(Color(hex: "#62626D", default: .gray)).font(.system(size: 16))
                                    }
                                }
                            }

                            Button(action: {}) {
                                HStack(spacing: 10) {
                                    Rectangle().fill(Color(hex: "#2C2C35", default: .black))
                                        .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                            Image(systemName: "person.fill.questionmark").foregroundStyle(.blue).font(.system(size: 14))
                                        }

                                    HStack {
                                        Text("자주 묻는 질문").font(.title3).fontWeight(.bold).foregroundStyle(.white)
                                        Spacer()
                                        Image(systemName: "chevron.right").fontWeight(.semibold).foregroundStyle(Color(hex: "#62626D", default: .gray)).font(.system(size: 16))
                                    }
                                }
                            }

                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 20)

                    }.frame(maxWidth: .infinity, alignment: .leading).padding(.top).padding(.horizontal)
                }
                .padding(.bottom)

                Divider().frame(height: 15).background(.black)

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("앱 정보").font(.title2).fontWeight(.bold).lineLimit(1)

                        VStack(spacing: 18) {
                            HStack(spacing: 10) {
                                Rectangle().fill(Color(hex: "#2C2C35", default: .black))
                                    .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                        Image(systemName: "info.circle.fill").foregroundStyle(.gray).font(.system(size: 16))
                                    }

                                HStack(spacing: 10) {
                                    Text("앱 버전").font(.title3).fontWeight(.bold).foregroundStyle(.white)
                                    Text("v 1.05 (10)").font(.footnote).fontWeight(.semibold).foregroundStyle(.gray)
                                }
                                Spacer()
                            }

                            HStack(alignment: .top, spacing: 10) {
                                Rectangle().fill(Color(hex: "#2C2C35", default: .black))
                                    .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                        Image(systemName: "info.circle.fill").foregroundStyle(.gray).font(.system(size: 16))
                                    }
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 10) {
                                        Text("문의/피드백").font(.title3).fontWeight(.bold).foregroundStyle(.white)
                                        Button(action: {}) {
                                            Text("jessebae0123@gmail.com").font(.footnote).fontWeight(.semibold)
                                        }
                                    }

                                    Text("문의사항이나 피드백을 보내주세요").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color(hex: "#7E7E87", default: .gray)).lineLimit(1)
                                }.padding(.top, 2.5)

                                Spacer()
                            }

                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 20)

                    }.frame(maxWidth: .infinity, alignment: .leading).padding(.top).padding(.horizontal)
                }
                .padding(.bottom)

                Divider().frame(height: 15).background(.black)

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("약관 및 정책").font(.title2).fontWeight(.bold).lineLimit(1)

                        VStack(spacing: 18) {
                            Button(action: {}) {
                                HStack(spacing: 10) {
                                    HStack {
                                        Text("서비스 이용 약관").font(.title3).fontWeight(.bold).foregroundStyle(.white)
                                        Spacer()
                                        Image(systemName: "chevron.right").fontWeight(.semibold).foregroundStyle(Color(hex: "#62626D", default: .gray)).font(.system(size: 16))
                                    }
                                }
                            }

                            Button(action: {}) {
                                HStack(spacing: 10) {
                                    HStack {
                                        Text("개인정보 처리방침").font(.title3).fontWeight(.bold).foregroundStyle(.white)
                                        Spacer()
                                        Image(systemName: "chevron.right").fontWeight(.semibold).foregroundStyle(Color(hex: "#62626D", default: .gray)).font(.system(size: 16))
                                    }
                                }
                            }

                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 20)

                    }.frame(maxWidth: .infinity, alignment: .leading).padding(.top).padding(.horizontal)
                }
                .padding(.bottom)

                Spacer()
            }
            .background {
                UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30)
                    .fill(Color(hex: "#101013", default: .black))
            }
        }
        .background(Color(hex: "#1D1D24", default: .black))
        .overlay(alignment: .bottom) {
            GeometryReader { proxy in
                Color(hex: "#101013", default: .black)
                    .frame(height: proxy.safeAreaInsets.bottom)
                    .frame(maxWidth: .infinity)
                    .ignoresSafeArea(edges: .bottom)
                    .allowsHitTesting(false)
                    .opacity(proxy.safeAreaInsets.bottom > 0 ? 1 : 0)
            }
            .frame(height: 0)
        }
    }

    @ViewBuilder
    private func destinationView(for destinationStore: StoreOf<SettingFeature.Path>) -> some View {
        switch destinationStore.state {
        case .dataManage:
            if let store = destinationStore.scope(state: \.dataManage, action: \.dataManage) {
                DataManageView(store: store)
            }
        case .myInfo:
            if let store = destinationStore.scope(state: \.myInfo, action: \.myInfo) {
                MyInfoView(store: store)
            }
        }
    }

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            mainContent

        } destination: { destinationStore in
            destinationView(for: destinationStore)
        }
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        store.send(.logoutButtonTapped)
                    } label: {
                        Label("로그아웃", systemImage: "rectangle.portrait.and.arrow.right")
                    }

                    Button(role: .destructive) {
                        store.send(.deleteAccountButtonTapped)
                    } label: {
                        Label("회원 탈퇴", systemImage: "person.crop.circle.badge.xmark")
                    }
                } label: {
                    Text("계정 관리")
                }
            }
        }
        .onAppear { store.send(.onAppear) }
        .alert($store.scope(state: \.alert, action: \.alert))
    }
}

#Preview {
    NavigationStack {
        SettingView(store: Store(initialState: SettingFeature.State(), reducer: {
            SettingFeature()
        }))
    }
}
