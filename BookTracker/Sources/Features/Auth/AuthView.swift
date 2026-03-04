//
//  AuthView.swift
//  BookTracker
//
//  Created by 배성연 on 2/2/26.
//

import ComposableArchitecture
import SwiftUI

struct PressTintButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.blue.opacity(0.85) : Color.blue)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct DefaultButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        Button(action: action) {
            label()
                .fontWeight(.bold)
                .padding()
                .frame(maxWidth: .infinity)
        }
        .foregroundStyle(.white)
        .buttonStyle(PressTintButtonStyle())
        .cornerRadius(10)
    }
}

struct AuthView: View {
    @Bindable var store: StoreOf<AuthFeature>
    private var mainContent: some View {
        GeometryReader { proxy in
            VStack {
                // 위 영역
                VStack {
                    Circle().foregroundStyle(.blue).frame(width: 200)
                }
                .frame(height: proxy.size.height * 0.7)
                .frame(maxWidth: .infinity)

                // 아래 영역
                VStack(spacing: 10) {
                    Spacer()
                    DefaultButton(action: {
                        store.send(.emailLoginButtonTapped)
                    }) {
                        Text("이메일 로그인")
                    }

                    Button(action: {
                        store.send(.snsLoginButtonTapped(.google))
                    }) {
                        Group {
                            if store.isGoogleLoginLoading {
                                HStack(spacing: 8) {
                                    ProgressView().tint(.white)
                                    Text("구글 로그인 중…")
                                        .fontWeight(.bold)
                                        .font(.headline)
                                }
                            } else {
                                HStack {
                                    Image("GoogleLogo")
                                        .resizable()
                                        .renderingMode(.original)
                                        .frame(width: 20, height: 20)

                                    Text("구글 로그인")
                                        .fontWeight(.bold)
                                        .font(.headline)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(store.isGoogleLoginLoading)
                    .foregroundStyle(.white)
                    .background(Color(hex: "#2C2C35", default: .accentColor))
                    .cornerRadius(10)

                    Button(action: {
                        store.send(.snsLoginButtonTapped(.apple))
                    }) {
                        Group {
                            if store.isAppleLoginLoading {
                                HStack(spacing: 8) {
                                    ProgressView().tint(.white)
                                    Text("애플 로그인 중…")
                                        .fontWeight(.bold)
                                        .font(.headline)
                                }
                            } else {
                                Label("애플 로그인", systemImage: "apple.logo")
                                    .fontWeight(.bold)
                                    .font(.headline)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(store.isAppleLoginLoading)
                    .foregroundStyle(.white)
                    .background(Color(hex: "#2C2C35", default: .accentColor))
                    .cornerRadius(10)

                }.frame(height: proxy.size.height * 0.3).padding(.horizontal)
            }
            .background(Color(hex: "#101013", default: .black))
        }
    }

    @ViewBuilder
    private func destinationView(for destinationStore: StoreOf<AuthFeature.Path>) -> some View {
        switch destinationStore.state {
        case .emailLogin:
            if let store = destinationStore.scope(state: \.emailLogin, action: \.emailLogin) {
                EmailLoginView(store: store)
            }
        case .signup:
            if let store = destinationStore.scope(state: \.signup, action: \.signup) {
                SignupView(store: store)
            }
        }
    }

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            mainContent
        } destination: { destinationStore in
            destinationView(for: destinationStore)
        }
        .alert($store.scope(state: \.alert, action: \.alert))
    }
}

#Preview {
    AuthView(store: Store(initialState: AuthFeature.State(), reducer: {
        AuthFeature()
    }))
}
