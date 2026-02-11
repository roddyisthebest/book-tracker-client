//
//  CollectionFormView.swift
//  BookTracker
//
//  Created by 배성연 on 2/7/26.
//
import ComposableArchitecture
import SwiftUI

struct CollectionFormView: View {
    @Bindable var store: StoreOf<CollectionFormFeature>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                VStack {
                    HStack {
                        FormLabel(text: "이름")
                        Spacer()
                    }
                    TextField("이름",
                              text: $store.title,
                              prompt: Text("컬렉션 이름을 입력해주세요").foregroundStyle(.white.opacity(0.4)))
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color(hex: "#17171C", default: .accentColor))
                        .cornerRadius(15)
                }

                VStack {
                    HStack {
                        FormLabel(text: "설명")
                        Spacer()
                    }

                    ZStack(alignment: .topLeading) {
                        if store.description.isEmpty {
                            Text("컬렉션 설명을 입력해주세요")
                                .foregroundStyle(.white.opacity(0.4))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                        }

                        TextEditor(text: $store.description)
                            .foregroundStyle(.white)
                            .padding(12)
                            .frame(height: 150)
                            .scrollIndicators(.visible)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .textInputAutocapitalization(.sentences)
                            .autocorrectionDisabled(false)
                    }
                    .background(Color(hex: "#17171C", default: .accentColor))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                }
                Spacer()
                if store.isEditing {
                    DefaultButton(action: {
                        store.send(.deleteButtonTapped)
                    }) { Text("삭제하기") }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(hex: "#2C2C35", default: .black))
            .navigationTitle(store.isEditing ? "컬렉션 수정" : "컬렉션 생성")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label("뒤로가기", systemImage: "chevron.left")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if store.isEditing {
                        Button("수정하기") {
                            store.send(.updateButtonTapped)
                        }
                        .disabled(!store.isSubmitEnabled)
                    } else {
                        Button("만들기") {
                            store.send(.createButtonTapped)
                        }
                    }
                }
            }
            .alert($store.scope(state: \.alert, action: \.alert))
        }
    }
}

#Preview {
    CollectionFormView(
        store: Store(
            initialState: CollectionFormFeature.State(collection: Collection(id: UUID(1), isDefault: false, title: "asdd", description: "asdsdsd")),
            reducer: { CollectionFormFeature() }
        )
    )
}
