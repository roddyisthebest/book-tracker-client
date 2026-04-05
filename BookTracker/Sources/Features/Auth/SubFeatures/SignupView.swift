//
//  SignupView.swift
//  BookTracker
//
//  Created by 배성연 on 2/25/26.
//
import ComposableArchitecture
import SwiftUI

struct SignupView: View {
    @Bindable var store: StoreOf<SignupFeature>
    @Environment(\.dismiss) private var dismiss
    @State private var isPasswordVisible: Bool = false
    @State private var isPasswordConfirmationVisible: Bool = false

    var body: some View {
        VStack(spacing: 30) {
            VStack {
                HStack {
                    FormLabel(text: "이메일")
                    Spacer()
                }
                TextField("",
                          text: $store.email,
                          prompt: Text("이메일을 입력해주세요").foregroundStyle(Color.appSecondaryText.opacity(0.6)))
                    .foregroundStyle(Color.appPrimaryText)
                    .padding()
                    .background(Color.appSurface)
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
                              prompt: Text("비밀번호를 입력해주세요").foregroundStyle(Color.appSecondaryText.opacity(0.6)))
                        .textContentType(.password)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .foregroundStyle(Color.appPrimaryText)
                        .padding()
                        .background(Color.appSurface)
                        .cornerRadius(15)
                        .overlay(alignment: .trailing) {
                            Button {
                                isPasswordVisible.toggle()
                            } label: {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundStyle(Color.appSecondaryText.opacity(0.8))
                            }
                            .padding(.trailing, 12)
                        }
                } else {
                    SecureField("",
                                text: $store.password,
                                prompt: Text("비밀번호를 입력해주세요").foregroundStyle(Color.appSecondaryText.opacity(0.6)))
                        .textContentType(.password)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .foregroundStyle(Color.appPrimaryText)
                        .padding()
                        .background(Color.appSurface)
                        .cornerRadius(15)
                        .overlay(alignment: .trailing) {
                            Button {
                                isPasswordVisible.toggle()
                            } label: {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundStyle(Color.appSecondaryText.opacity(0.8))
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

            VStack {
                HStack {
                    FormLabel(text: "비밀번호 확인")
                    Spacer()
                }

                if isPasswordConfirmationVisible {
                    TextField("",
                              text: $store.passwordConfirmation,
                              prompt: Text("비밀번호를 다시 입력해주세요").foregroundStyle(Color.appSecondaryText.opacity(0.6)))
                        .textContentType(.password)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .foregroundStyle(Color.appPrimaryText)
                        .padding()
                        .background(Color.appSurface)
                        .cornerRadius(15)
                        .overlay(alignment: .trailing) {
                            Button {
                                isPasswordConfirmationVisible.toggle()
                            } label: {
                                Image(systemName: isPasswordConfirmationVisible ? "eye.slash" : "eye")
                                    .foregroundStyle(Color.appSecondaryText.opacity(0.8))
                            }
                            .padding(.trailing, 12)
                        }
                } else {
                    SecureField("",
                                text: $store.passwordConfirmation,
                                prompt: Text("비밀번호를 다시 입력해주세요").foregroundStyle(Color.appSecondaryText.opacity(0.6)))
                        .textContentType(.password)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .foregroundStyle(Color.appPrimaryText)
                        .padding()
                        .background(Color.appSurface)
                        .cornerRadius(15)
                        .overlay(alignment: .trailing) {
                            Button {
                                isPasswordConfirmationVisible.toggle()
                            } label: {
                                Image(systemName: isPasswordConfirmationVisible ? "eye.slash" : "eye")
                                    .foregroundStyle(Color.appSecondaryText.opacity(0.8))
                            }
                            .padding(.trailing, 12)
                        }
                }
                if let error = store.passwordConfirmationErrorToShow {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 5)
                }
            }

            Spacer()
            DefaultButton(action: { store.send(.submitButtonTapped) }) {
                ZStack {
                    Text("회원가입")
                        .opacity(store.isLoading ? 0 : 1)
                    if store.isLoading {
                        ProgressView()
                            .tint(Color.appAccent)
                    }
                }
            }
            .disabled(store.isLoading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.appBackground)
        .navigationTitle("이메일 회원가입")
        .navigationBarTitleDisplayMode(.inline)
        .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
    }
}

#Preview {
    NavigationStack {
        SignupView(
            store: Store(
                initialState: SignupFeature.State(),
                reducer: { SignupFeature() }
            )
        )
    }
}
