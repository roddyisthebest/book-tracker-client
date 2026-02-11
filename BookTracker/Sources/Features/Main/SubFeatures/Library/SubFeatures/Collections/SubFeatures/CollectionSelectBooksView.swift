//
//  CollectionSelectBooksView.swift
//  BookTracker
//
//  Created by 배성연 on 2/8/26.
//

import ComposableArchitecture
import SwiftUI

private struct BookRowView: View {
    let title: String
    let author: String
    let publisher: String
    let isbn: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        SelectBookRow(
            title: title,
            author: author,
            publisher: publisher,
            isbn: isbn,
            isSelected: isSelected,
            onTap: onTap
        )
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 7.5, leading: 20, bottom: 7.5, trailing: 20))
        .background(Color(hex: "#17171C"))
        .cornerRadius(10)
    }
}

struct CollectionSelectBooksView: View {
    var store: StoreOf<CollectionSelectBooksFeature>
    @Environment(\.dismiss) private var dismiss

    private typealias Feature = CollectionSelectBooksFeature

    @ViewBuilder
    private var booksList: some View {
        List {
            ForEach(store.books, id: \.id) { book in
                BookRowView(
                    title: book.title,
                    author: book.author,
                    publisher: book.publisher,
                    isbn: book.isbn,
                    isSelected: store.selectedIds.contains(book.id),
                    onTap: { store.send(.bookSelected(id: book.id)) }
                )
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .listRowBackground(Color.clear)
        .background(Color(hex: "#2C2C35", default: .black))
    }

    var body: some View {
        NavigationStack {
            booksList
                .navigationTitle("구매한책")
                .navigationBarTitleDisplayMode(.large)
                .navigationBarBackButtonHidden(true)
                .navigationSubtitle("책을 삭제하거나 추가해보세요.")
                .toolbar { toolbarContent }
                .overlay(alignment: .bottom) { bottomBar }
                .sheet(store: store.scope(state: \.$addBooks, action: \.addBooks)) { addBooksStore in
                    AddBooksView(store: addBooksStore)
                }
                .alert(store: store.scope(state: \.$alert, action: \.alert))
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                Label("뒤로가기", systemImage: "chevron.left")
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("전체 선택", systemImage: "checkmark.circle") {
                    store.send(.bookAllSelected)
                }
                Button("전체 해제", systemImage: "xmark.circle") {
                    store.send(.bookAllDisselected)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                store.send(.saveButtonTapped)
            } label: {
                Text("저장하기")
            }
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        HStack(spacing: 10) {
            DefaultButton(action: {
                store.send(.addButtonTapped)
            }) { Text("추가하기") }

            if store.isSubmitEnabled {
                DefaultButton(action: {
                    store.send(.deleteButtonTapped)
                }) { Text("삭제하기 \(store.selectedIds.count)") }
            }
        }
        .padding(.horizontal, 25)
    }
}

#Preview {
    CollectionSelectBooksView(store: Store(initialState: CollectionSelectBooksFeature.State(), reducer: {
        CollectionSelectBooksFeature()
    }))
}
