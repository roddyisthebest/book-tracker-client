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
                    FormLabel(text: String(localized: "email"))
                    Spacer()
                }
                TextField("",
                          text: $store.email,
                          prompt: Text("enter_email_placeholder").foregroundStyle(Color.appSecondaryText.opacity(0.6)))
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
                    FormLabel(text: String(localized: "password"))
                    Spacer()
                }

                if isPasswordVisible {
                    TextField("",
                              text: $store.password,
                              prompt: Text("enter_password_placeholder").foregroundStyle(Color.appSecondaryText.opacity(0.6)))
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
                                prompt: Text("enter_password_placeholder").foregroundStyle(Color.appSecondaryText.opacity(0.6)))
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

            Spacer()
            VStack(spacing: 20) {
                DefaultButton(action: { store.send(.submitButtonTapped) }) {
                    ZStack {
                        Text("login")
                            .opacity(store.isLoading ? 0 : 1)
                        if store.isLoading {
                            ProgressView()
                                .tint(Color.appAccent)
                        }
                    }
                }
                .disabled(store.isLoading)
                Button(action: {
                    store.send(.signupButtonTapped)
                }) {
                    Text("signup").foregroundStyle(.gray).fontWeight(.semibold)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.appBackground)
        .navigationTitle("email_login")
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
