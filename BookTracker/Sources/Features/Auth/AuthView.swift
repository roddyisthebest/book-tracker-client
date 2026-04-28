//
//  AuthView.swift
//  BookTracker
//
//  Created by 배성연 on 2/2/26.
//

import ComposableArchitecture
import SwiftUI

struct PressTintButtonStyle: ButtonStyle {
    var color: Color = .appAccent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? color.opacity(0.85) : color)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct DefaultButton<Label: View>: View {
    let action: () -> Void
    var color: Color = .appAccent
    @ViewBuilder let label: () -> Label

    var body: some View {
        Button(action: action) {
            label()
                .fontWeight(.bold)
                .padding()
                .frame(maxWidth: .infinity)
        }
        .foregroundStyle(.white)
        .buttonStyle(PressTintButtonStyle(color: color))
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
                    Image("Transparent_AppIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200)
                }
                .frame(height: proxy.size.height * 0.7)
                .frame(maxWidth: .infinity)

                // 아래 영역
                VStack(spacing: 10) {
                    Spacer()
                    DefaultButton(action: {
                        store.send(.emailLoginButtonTapped)
                    }) {
                        Text("email_login")
                    }

                    Button(action: {
                        store.send(.snsLoginButtonTapped(.google))
                    }) {
                        Group {
                            if store.isGoogleLoginLoading {
                                HStack(spacing: 8) {
                                    ProgressView().tint(Color.appAccent)
                                    Text("google_login_loading")
                                        .fontWeight(.bold)
                                        .font(.headline)
                                }
                            } else {
                                HStack {
                                    Image("GoogleLogo")
                                        .resizable()
                                        .renderingMode(.original)
                                        .frame(width: 20, height: 20)

                                    Text("google_login")
                                        .fontWeight(.bold)
                                        .font(.headline)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(store.isGoogleLoginLoading)
                    .foregroundStyle(Color.appPrimaryText)
                    .background(Color.appSurface)
                    .cornerRadius(10)

                    Button(action: {
                        store.send(.snsLoginButtonTapped(.apple))
                    }) {
                        Group {
                            if store.isAppleLoginLoading {
                                HStack(spacing: 8) {
                                    ProgressView().tint(Color.appAccent)
                                    Text("apple_login_loading")
                                        .fontWeight(.bold)
                                        .font(.headline)
                                }
                            } else {
                                Label("apple_login", systemImage: "apple.logo")
                                    .fontWeight(.bold)
                                    .font(.headline)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(store.isAppleLoginLoading)
                    .foregroundStyle(Color.appPrimaryText)
                    .background(Color.appSurface)
                    .cornerRadius(10)

                }.frame(height: proxy.size.height * 0.3).padding(.horizontal)
            }
            .background(Color.appBackground)
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
