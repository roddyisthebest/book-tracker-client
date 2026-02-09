//
//  CollectionAddBooksView.swift
//  BookTracker
//
//  Created by 배성연 on 2/9/26.
//

import ComposableArchitecture
import SwiftUI

struct AddBooksView: View {
    @Bindable var store: StoreOf<AddBooksFeature>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // 3-column grid
                    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(store.filteredBooks, id: \.id) { book in
                            BookGridItem(
                                title: book.title,
                                author: book.author,
                                imageURL: book.imageUrl,
                                isSelected: store.selectedIds.contains(book.id),
                                onTap: { store.send(.bookSelected(book.id)) }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .background(Color(hex: "#2C2C35", default: .black))
            .navigationTitle("책 추가")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .navigationSubtitle("컬렉션에 책을 추가해보세요")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label("뒤로가기", systemImage: "chevron.left")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 10) {
                    if store.isSubmitEnabled {
                        DefaultButton(action: {
                            store.send(.addButtonTapped)
                        }) { Text("추가하기") }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
        }
    }
}

#Preview {
    AddBooksView(store: Store(initialState: AddBooksFeature.State(unSelectableIds: Set()), reducer: {
        AddBooksFeature()
    }))
}
