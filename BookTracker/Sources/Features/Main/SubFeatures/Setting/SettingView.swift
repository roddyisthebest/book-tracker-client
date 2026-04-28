//
//  SettingView.swift
//  BookTracker
//
//  Created by 배성연 on 2/22/26.
//

import ComposableArchitecture
import Kingfisher
import SwiftUI

struct SettingView: View {
    @Bindable var store: StoreOf<SettingFeature>

    private var mainContent: some View {
        ScrollView {
            Button(action: {
                store.send(.navigateButtonTapped(.myInfo))
            }) {
                if let profile = store.profile {
                    HStack {
                        Circle()
                            .fill(Color.appSurface)
                            .frame(width: 60, height: 60)
                            .overlay {
                                if let url = profile.profileImageURL {
                                    KFImage(url)
                                        .placeholder {
                                            ProgressView().tint(.gray)
                                        }
                                        .retry(maxCount: 2, interval: .seconds(1))
                                        .fade(duration: 0.2)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.fill")
                                        .foregroundStyle(.gray)
                                        .font(.system(size: 30))
                                }
                            }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(profile.name ?? "unknown")
                                .font(.title2)
                                .fontWeight(.bold)
                                .lineLimit(1)
                                .foregroundStyle(Color.appPrimaryText)

                            Text("manage_my_info")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.appSecondaryText)
                                .lineLimit(1)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 16))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.appSecondaryText)
                    }
                    .padding(.horizontal)

                } else {
                    HStack {
                        Circle()
                            .fill(Color.appSurface)
                            .frame(width: 60, height: 60)

                        VStack(alignment: .leading, spacing: 6) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.appSurface)
                                .frame(width: 120, height: 20)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.appSurface)
                                .frame(width: 80, height: 16)
                        }

                        Spacer()
                    }
                    .padding(.horizontal)
                    .redacted(reason: .placeholder)
                }

            }.padding(.bottom, 10)

            VStack(spacing: 15) {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("app_data").font(.title2).fontWeight(.bold).lineLimit(1)
                        Text("app_data_description").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.appSecondaryText).lineLimit(1)

                        VStack(spacing: 18) {
                            Button(action: {
                                store.send(.navigateButtonTapped(.dataManage))
                            }) {
                                HStack(spacing: 10) {
                                    Rectangle().fill(Color.appSurface)
                                        .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                            Image(systemName: "externaldrive.fill").foregroundStyle(.cyan).font(.system(size: 15))
                                        }

                                    HStack {
                                        Text("data_management").font(.title3).fontWeight(.bold).foregroundStyle(Color.appPrimaryText)
                                        Spacer()
                                        Image(systemName: "chevron.right").fontWeight(.semibold).foregroundStyle(Color.appSecondaryText).font(.system(size: 16))
                                    }
                                }
                            }

                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 20)

                    }.frame(maxWidth: .infinity, alignment: .leading).padding(.top).padding(.horizontal)
                }
                .padding(.bottom)
                .padding(.top, 10)

                Rectangle().fill(Color.appSurfaceDeeper).frame(height: 15)

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("app_usage").font(.title2).fontWeight(.bold).lineLimit(1)
                        Text("app_usage_description").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.appSecondaryText).lineLimit(1)

                        VStack(spacing: 18) {
                            Button(action: {
                                store.send(.openPageButtonTapped(.userGuide))
                            }) {
                                HStack(spacing: 10) {
                                    Rectangle().fill(Color.appSurface)
                                        .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                            Image(systemName: "questionmark.app.fill").foregroundStyle(.blue).font(.system(size: 16))
                                        }

                                    HStack {
                                        Text("user_guide").font(.title3).fontWeight(.bold).foregroundStyle(Color.appPrimaryText)
                                        Spacer()
                                        Image(systemName: "chevron.right").fontWeight(.semibold).foregroundStyle(Color.appSecondaryText).font(.system(size: 16))
                                    }
                                }
                            }

                            Button(action: {
                                store.send(.openPageButtonTapped(.faq))
                            }) {
                                HStack(spacing: 10) {
                                    Rectangle().fill(Color.appSurface)
                                        .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                            Image(systemName: "person.fill.questionmark").foregroundStyle(.blue).font(.system(size: 14))
                                        }

                                    HStack {
                                        Text("faq").font(.title3).fontWeight(.bold).foregroundStyle(Color.appPrimaryText)
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
                        Text("app_info").font(.title2).fontWeight(.bold).lineLimit(1)

                        VStack(spacing: 18) {
                            HStack(spacing: 10) {
                                Rectangle().fill(Color.appSurface)
                                    .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                        Image(systemName: "info.circle.fill").foregroundStyle(.gray).font(.system(size: 16))
                                    }

                                HStack(spacing: 10) {
                                    Text("app_version").font(.title3).fontWeight(.bold).foregroundStyle(Color.appPrimaryText)
                                    Text("v 1.05 (10)").font(.footnote).fontWeight(.semibold).foregroundStyle(.gray)
                                }
                                Spacer()
                            }

                            HStack(alignment: .top, spacing: 10) {
                                Rectangle().fill(Color.appSurface)
                                    .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                        Image(systemName: "info.circle.fill").foregroundStyle(.gray).font(.system(size: 16))
                                    }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("contact_feedback").font(.title3).fontWeight(.bold).foregroundStyle(Color.appPrimaryText)
                                    Button(action: {}) {
                                        Text("jessebae0123@gmail.com").font(.footnote).fontWeight(.semibold)
                                    }
                                    Text("contact_feedback_description").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.appSecondaryText).lineLimit(1)
                                }.padding(.top, 2.5)

                                Spacer()
                            }

                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 20)

                    }.frame(maxWidth: .infinity, alignment: .leading).padding(.top).padding(.horizontal)
                }
                .padding(.bottom)

                Rectangle().fill(Color.appSurfaceDeeper).frame(height: 15)

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("terms_and_policies").font(.title2).fontWeight(.bold).lineLimit(1)

                        VStack(spacing: 18) {
                            Button(action: {
                                store.send(.navigateButtonTapped(.termsOfService))
                            }) {
                                HStack(spacing: 10) {
                                    HStack {
                                        Text("terms_of_service").font(.title3).fontWeight(.bold).foregroundStyle(Color.appPrimaryText)
                                        Spacer()
                                        Image(systemName: "chevron.right").fontWeight(.semibold).foregroundStyle(Color.appSecondaryText).font(.system(size: 16))
                                    }
                                }
                            }

                            Button(action: {
                                store.send(.navigateButtonTapped(.privacyPolicy))
                            }) {
                                HStack(spacing: 10) {
                                    HStack {
                                        Text("privacy_policy").font(.title3).fontWeight(.bold).foregroundStyle(Color.appPrimaryText)
                                        Spacer()
                                        Image(systemName: "chevron.right").fontWeight(.semibold).foregroundStyle(Color.appSecondaryText).font(.system(size: 16))
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
                    .fill(Color.appBackground)
            }
        }
        .background(Color.appHeaderSurface)
        .overlay(alignment: .bottom) {
            GeometryReader { proxy in
                Color.appBackground
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
        case .resetData:
            if let store = destinationStore.scope(state: \.resetData, action: \.resetData) {
                ResetDataView(store: store)
            }
        case .termsOfService:
            TermsOfServiceView()
        case .privacyPolicy:
            PrivacyPolicyView()
        }
    }

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            mainContent

        } destination: { destinationStore in
            destinationView(for: destinationStore)
        }
        .navigationTitle("settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        store.send(.logoutButtonTapped)
                    } label: {
                        Label("logout", systemImage: "rectangle.portrait.and.arrow.right")
                    }

                    Button(role: .destructive) {
                        store.send(.deleteAccountButtonTapped)
                    } label: {
                        Label("delete_account", systemImage: "person.crop.circle.badge.xmark")
                    }
                } label: {
                    Text("account_management")
                }
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .sheet(isPresented: Binding(
            get: { store.safariURL != nil },
            set: { if !$0 { store.send(.safariDismissed) } }
        )) {
            if let url = store.safariURL {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
        .disabled(store.isDeletingAccount)
        .overlay {
            if store.isDeletingAccount {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView().tint(.white)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingView(store: Store(initialState: SettingFeature.State(), reducer: {
            SettingFeature()
        }))
    }
}
