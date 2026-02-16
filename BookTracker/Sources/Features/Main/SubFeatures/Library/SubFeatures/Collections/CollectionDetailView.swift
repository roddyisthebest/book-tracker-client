//
//  CollectionDetailView.swift
//  BookTracker
//
//  Created by 배성연 on 2/11/26.
//

import ComposableArchitecture
import SwiftUI

private struct BookRowView: View {
    let book: Book
    let onTap: () -> Void
    let onDelete: () -> Void
    var body: some View {
        BookRow(book: book, onTap: onTap, onDelete: onDelete)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 7.5, leading: 20, bottom: 7.5, trailing: 20))
            .background(Color(hex: "#17171C"))
            .cornerRadius(10)
    }
}

struct CollectionDetailView: View {
    @Bindable var store: StoreOf<CollectionDetailFeature>
    @Environment(\.dismiss) private var dismiss

    private typealias Feature = CollectionDetailFeature

    @ViewBuilder
    private var booksList: some View {
        List {
            ForEach(store.books, id: \.id) { book in
                BookRowView(
                    book: book,
                    onTap: {
                        store.send(.bookCardTapped(book.id))
                    },
                    onDelete: {
                        store.send(.deleteButtonTapped(book.id))
                    }
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
                .navigationSubtitle("영수증 내역으로 자동 생성되는 컬렉션입니다.")
                .toolbar { toolbarContent }
                .sheet(item: $store.scope(state: \.destination?.formCollection, action: \.destination.formCollection)) { formCollectionStore in
                    NavigationStack {
                        CollectionFormView(store: formCollectionStore)
                    }
                }
                .sheet(item: $store.scope(state: \.destination?.selectBooks, action: \.destination.selectBooks)) {
                    selectBookStore in
                    NavigationStack {
                        CollectionSelectBooksView(store: selectBookStore)
                    }
                }
                .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
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
                Menu {
                    Button("컬렉션 편집하기", systemImage: "books.vertical.circle") {
                        store.send(.editButtonTapped(.collection))
                    }
                    Button("책 편집하기", systemImage: "apple.books.pages") {
                        store.send(.editButtonTapped(.books))
                    }

                } label: {
                    Image(systemName: "pencil.circle")
                    Text("편집하기")
                }
                Picker("정렬", selection: $store.sortOption) {
                    Text("오래된순").tag(BookSortOption.oldest)
                    Text("최신순").tag(BookSortOption.newest)
                    Text("제목순(가나다)").tag(BookSortOption.titleAsc)
                    Text("제목순(반대)").tag(BookSortOption.titleDesc)
                }
                .pickerStyle(.inline)
                // 여기 정렬 양뱡향 바인딩 추가해바
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
}

#Preview {
    CollectionDetailView(store: Store(initialState: CollectionDetailFeature.State(), reducer: {
        CollectionDetailFeature()
    }))
}
