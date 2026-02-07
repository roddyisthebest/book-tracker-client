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
        VStack {
            // Header at top
            ZStack {
                Text("컬렉션 생성")
                    .font(.headline)
                    .foregroundStyle(.white)

                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
                    }
                    Spacer()
                    if store.isEditing {
                        Button("수정하기") {
                            store.send(.updateButtonTapped)
                        }
                        .disabled(!store.isSubmitEnabled)
                        .foregroundStyle(store.isSubmitEnabled ? .white : .white.opacity(0.2))
                    } else {
                        Button("만들기") {
                            store.send(.createButtonTapped)
                        }.foregroundStyle(.white)
                    }

                }.padding(.horizontal, 10)
            }
            .frame(height: 52)
            .padding(.horizontal)
            .padding(.vertical, 10)

            VStack(spacing: 30) {
                VStack {
                    HStack {
                        FormLabel(text: "이름")
                        Spacer()
                    }
                    TextField("이름",
                              text: $store.name,
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
                                .foregroundStyle(.white.opacity(0.4)) // placeholder는 밝은 색 + 투명도 권장
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
                    .clipShape(RoundedRectangle(cornerRadius: 15)) // 내용까지 라운드로 잘라줌
                }
                Spacer()
                if store.isEditing {
                    DefaultButton(action: {
                        store.send(.deleteButtonTapped)
                    }) { Text("삭제하기") }
                }

            }.frame(maxWidth: .infinity, maxHeight: .infinity).padding(.horizontal, 20).padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#2C2C35", default: .black))
        .alert($store.scope(state: \.alert, action:
            \.alert))
    }
}

#Preview {
    CollectionFormView(
        store: Store(
            initialState: CollectionFormFeature.State(id: UUID(), name: "", description: ""),
            reducer: { CollectionFormFeature() }
        )
    )
}
