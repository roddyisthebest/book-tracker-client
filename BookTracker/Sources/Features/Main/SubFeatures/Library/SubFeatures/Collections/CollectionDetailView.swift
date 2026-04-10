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
            .background(Color.appSurfaceDeep)
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

            Text("error_occurred")
                .font(.headline)
                .foregroundStyle(Color.appPrimaryText)

            Button(String(localized: "retry")) {
                store.send(.onAppear)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appSurface)
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
            .background(Color.appSurface)
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
            .navigationTitle(store.collection.name ?? String(localized: "collection"))
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
                Label("back", systemImage: "chevron.left")
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Menu {
                    Button(String(localized: "edit_collection"), systemImage: "books.vertical.circle") {
                        store.send(.editButtonTapped(.collection))
                    }
                    Button(String(localized: "edit_books"), systemImage: "apple.books.pages") {
                        store.send(.editButtonTapped(.books))
                    }

                } label: {
                    Image(systemName: "pencil.circle")
                    Text("edit")
                }
                Button(role: .destructive) {
                    store.send(.deleteButtonTapped)
                } label: {
                    Label("delete", systemImage: "trash")
                }
                .tint(.red)

                Picker("sort", selection: $store.sortOption) {
                    Text("sort_oldest").tag(BookSortOption.oldest)
                    Text("sort_newest").tag(BookSortOption.newest)
                    Text("sort_title_asc").tag(BookSortOption.titleAsc)
                    Text("sort_title_desc").tag(BookSortOption.titleDesc)
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
