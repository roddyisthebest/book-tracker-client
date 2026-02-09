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
    var store: StoreOf<AuthFeature>

    var body: some View {
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
                        store.send(.snsLoginButtonTapped(.apple))
                    }) {
                        Text("Apple로 계속")
                    }
                    DefaultButton(action: {
                        store.send(.snsLoginButtonTapped(.google))
                    }) {
                        Text("Google로 계속")
                    }
                }.frame(height: proxy.size.height * 0.3)
            }
        }
    }
}

#Preview {
    AuthView(store: Store(initialState: AuthFeature.State(), reducer: {
        AuthFeature()
    }))
}
