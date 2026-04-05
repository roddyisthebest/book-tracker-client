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

                if !store.isEditing {
                    VStack(alignment: .leading) {
                        FormLabel(text: "초기 책 선택 (선택 사항)")

                        Button(action: {
                            store.send(.presentBookPickerButtonTapped)
                        }) {
                            HStack {
                                Text("책 선택")
                                Spacer()

                                HStack(spacing: 10) {
                                    let selectedBookIds = store.selectedBookIds
                                    if !selectedBookIds.isEmpty {
                                        Text("\(selectedBookIds.count)권 선택됨").foregroundStyle(.foreground)
                                    }

                                    Image(systemName: "chevron.right").fontWeight(.semibold).foregroundStyle(.foreground)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .background(Color(hex: "#17171C", default: .accentColor))
                        .clipShape(RoundedRectangle(cornerRadius: 15))

                    }.frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()
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
                    if store.isLoading {
                        ProgressView()
                    } else if store.isEditing {
                        Button("수정하기") {
                            store.send(.updateButtonTapped)
                        }
                        .disabled(!store.isSubmitEnabled || store.isLoading)

                    } else {
                        Button("생성하기") {
                            store.send(.createButtonTapped)
                        }
                        .disabled(!store.isSubmitEnabled || store.isLoading)
                    }
                }
            }
            .sheet(item: $store.scope(state: \.addBooks, action: \.addBooks)) { addBooksStore in
                NavigationStack {
                    AddBooksView(store: addBooksStore)
                }
            }
            .alert($store.scope(state: \.alert, action: \.alert))
        }
    }
}

#Preview {
    CollectionFormView(
        store: Store(
            initialState: CollectionFormFeature.State(collection: UserCollection(id: UUID(), userId: UUID(), name: "My Collection", isDefault: false, createdAt: Date(), description: "")),
            reducer: { CollectionFormFeature() }
        )
    )
}
