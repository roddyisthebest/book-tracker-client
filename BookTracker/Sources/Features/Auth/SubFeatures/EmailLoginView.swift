//
//  EmailLoginView.swift
//  BookTracker
//
//  Created by 배성연 on 2/25/26.
//

import ComposableArchitecture
import SwiftUI

struct EmailLoginView: View {
    @Bindable var store: StoreOf<EmailLoginFeature>
    @Environment(\.dismiss) private var dismiss
    @State private var isPasswordVisible: Bool = false

    var body: some View {
        VStack(spacing: 30) {
            VStack {
                HStack {
                    FormLabel(text: "이메일")
                    Spacer()
                }
                TextField("",
                          text: $store.email,
                          prompt: Text("이메일을 입력해주세요").foregroundStyle(.white.opacity(0.4)))
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color(hex: "#2C2C35", default: .accentColor))
                    .cornerRadius(15)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                if let error = store.emailErrorToShow {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 5)
                }
            }

            VStack {
                HStack {
                    FormLabel(text: "비밀번호")
                    Spacer()
                }

                if isPasswordVisible {
                    TextField("",
                              text: $store.password,
                              prompt: Text("비밀번호를 입력해주세요").foregroundStyle(.white.opacity(0.4)))
                        .textContentType(.password)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color(hex: "#2C2C35", default: .accentColor))
                        .cornerRadius(15)
                        .overlay(alignment: .trailing) {
                            Button {
                                isPasswordVisible.toggle()
                            } label: {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            .padding(.trailing, 12)
                        }
                } else {
                    SecureField("",
                                text: $store.password,
                                prompt: Text("비밀번호를 입력해주세요").foregroundStyle(.white.opacity(0.4)))
                        .textContentType(.password)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color(hex: "#2C2C35", default: .accentColor))
                        .cornerRadius(15)
                        .overlay(alignment: .trailing) {
                            Button {
                                isPasswordVisible.toggle()
                            } label: {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            .padding(.trailing, 12)
                        }
                }
                if let error = store.passwordErrorToShow {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 5)
                }
            }

            Spacer()
            VStack(spacing: 20) {
                DefaultButton(action: { store.send(.submitButtonTapped) }) {
                    ZStack {
                        Text("로그인")
                            .opacity(store.isLoading ? 0 : 1)
                        if store.isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                }
                .disabled(store.isLoading)
                Button(action: {
                    store.send(.signupButtonTapped)
                }) {
                    Text("회원가입").foregroundStyle(.gray).fontWeight(.semibold)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(hex: "#101013", default: .black))
        .navigationTitle("이메일 로그인")
        .navigationBarTitleDisplayMode(.inline)
        .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
    }
}

#Preview {
    NavigationStack {
        EmailLoginView(
            store: Store(
                initialState: EmailLoginFeature.State(),
                reducer: { EmailLoginFeature() }
            )
        )
    }
}
