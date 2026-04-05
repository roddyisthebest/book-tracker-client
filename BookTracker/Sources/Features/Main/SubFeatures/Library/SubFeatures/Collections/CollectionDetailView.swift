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
    private var errorView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28))
                .foregroundStyle(.yellow)

            Text("문제가 발생했어요")
                .font(.headline)
                .foregroundStyle(.white)

            Button("다시 시도") {
                store.send(.onAppear)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#2C2C35", default: .black))
    }

    @ViewBuilder
    private var booksList: some View {
        ZStack {
            List {
                ForEach(store.books, id: \.id) { book in
                    BookRowView(
                        book: book,
                        onTap: {
                            store.send(.bookCardTapped(book.id))
                        },
                        onDelete: {
                            store.send(.deleteButtonTapped)
                        }
                    )
                }

                if store.isLoadingMore {
                    ProgressView()
                        .padding(.vertical, 12)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .listRowBackground(Color.clear)
            .background(Color(hex: "#2C2C35", default: .black))
            .allowsHitTesting(!(store.isLoading && store.books.isEmpty))
            .refreshable {
                await store.send(.onRefresh).finish()
            }

            if store.isDeleting {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .disabled(store.isDeleting)
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.errorMessage != nil {
                    errorView
                } else {
                    booksList
                }
            }
            .overlay {
                if store.isLoading && store.books.isEmpty {
                    ProgressView()
                        .scaleEffect(1.1)
                        .padding(16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .navigationTitle(store.collection.name ?? "컬렉션")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .navigationSubtitle(store.collection.description ?? "")
            .toolbar { toolbarContent }
            .task {
                await store.send(.onAppear).finish()
            }
            .sheet(item: $store.scope(state: \.destination?.formCollection, action: \.destination.formCollection)) { formCollectionStore in
                CollectionFormView(store: formCollectionStore)
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
                Button(role: .destructive) {
                    store.send(.deleteButtonTapped)
                } label: {
                    Label("삭제하기", systemImage: "trash")
                }
                .tint(.red)

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
    NavigationStack {
        CollectionDetailView(
            store: Store(
                initialState: CollectionDetailFeature.State(
                    collection: UserCollectionSummary(
                        id: UUID(),
                        userId: UUID(),
                        name: "읽고 싶은 책",
                        isDefault: false,
                        createdAt: Date(),
                        description: "나중에 읽을 책들을 모아둔 컬렉션",
                        previewBooks: [],
                        bookCount: 0
                    )
                ),
                reducer: {
                    CollectionDetailFeature()
                }
            )
        )
    }
}
