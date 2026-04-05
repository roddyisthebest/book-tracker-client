//
//  UpdateNameView.swift
//  BookTracker
//
//  Created by 배성연 on 2/22/26.
//

import ComposableArchitecture
import SwiftUI

struct UpdateNameView: View {
    @Bindable var store: StoreOf<UpdateNameFeature>
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        NavigationStack {
            List {
                VStack(alignment: .leading) {
                    Text("이름").foregroundStyle(.blue).font(.caption)
                    VStack(spacing: 7) {
                        HStack {
                            TextField(
                                "",
                                text: $store.name,
                                prompt: Text("이름").foregroundStyle(Color.appSecondaryText)
                            )
                            .foregroundStyle(Color.appPrimaryText)
                            .font(.system(size: 20, weight: .semibold))
                            .background(.clear)
                            .frame(height: 28)
                            .focused($isNameFieldFocused)
                            .task { isNameFieldFocused = true }
                            .submitLabel(.done)
                            .onSubmit {
                                guard store.isSubmittable else { return }
                                store.send(.updateButtonTapped)
                            }

                            if !store.name.isEmpty {
                                Button(action: {
                                    $store.name.wrappedValue = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill").foregroundStyle(.gray)
                                }
                            }
                        }

                        Color.blue.frame(height: 1)
                    }

                }.background(.clear)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .padding(0)
            .listStyle(.insetGrouped)
            .navigationTitle("이름을 입력해주세요")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label("뒤로가기", systemImage: "chevron.left")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.send(.updateButtonTapped)
                    } label: {
                        ZStack {
                            Text("저장하기")
                                .opacity(store.isLoading ? 0 : 1)

                            if store.isLoading {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(!store.isSubmittable || store.isLoading)
                }
            }
            .scrollContentBackground(.hidden) // 추가
            .background(Color.appSurface)
            .alert($store.scope(state: \.alert, action: \.alert))
        }
    }
}

#Preview {
    UpdateNameView(
        store: Store(
            initialState: UpdateNameFeature.State(name: "배성연"),
            reducer: { UpdateNameFeature() }
        )
    )
}
