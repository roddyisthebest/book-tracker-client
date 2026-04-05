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
    let thumbnail: String?

    let onTap: () -> Void

    var body: some View {
        SelectBookRow(
            title: title,
            author: author,
            publisher: publisher,
            isbn: isbn,
            thumbnail: thumbnail,
            isSelected: isSelected,
            onTap: onTap
        )
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 7.5, leading: 20, bottom: 7.5, trailing: 20))
        .background(Color.appSurfaceDeep)
        .cornerRadius(10)
    }
}

struct CollectionSelectBooksView: View {
    var store: StoreOf<CollectionSelectBooksFeature>
    @Environment(\.dismiss) private var dismiss

    private typealias Feature = CollectionSelectBooksFeature

    @ViewBuilder
    private var errorView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28))
                .foregroundStyle(.yellow)

            Text("문제가 발생했어요")
                .font(.headline)
                .foregroundStyle(Color.appPrimaryText)

            Button("다시 시도") {
                store.send(.onRefresh)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appSurface)
    }

    @ViewBuilder
    private var bookList: some View {
        List {
            ForEach(store.books, id: \.id) { book in
                BookRowView(
                    title: book.title,
                    author: book.author,
                    publisher: book.publisher,
                    isbn: book.isbn,
                    isSelected: store.selectedIds.contains(book.id),
                    thumbnail: book.imageUrl, onTap: { store.send(.bookSelected(id: book.id)) }
                )
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .listRowBackground(Color.clear)
        .background(Color.appSurface)
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.isError {
                    errorView
                }
                else {
                    bookList
                }
            }
            .overlay {
                if store.isLoading {
                    ProgressView()
                        .scaleEffect(1.1)
                        .padding(16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .navigationTitle("구매한책")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .navigationSubtitle("책을 삭제하거나 추가해보세요.")
            .toolbar { toolbarContent }
            .task {
                await store.send(.onAppear).finish()
            }
            .overlay(alignment: .bottom) { bottomBar }
            .sheet(store: store.scope(state: \.$addBooks, action: \.addBooks)) { addBooksStore in
                NavigationStack {
                    AddBooksView(store: addBooksStore)
                }
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
                HStack(spacing: 6) {
                    if store.isSyncing {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text("저장하기")
                }
            }
            .disabled(store.isSyncing)
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
    CollectionSelectBooksView(store: Store(initialState: CollectionSelectBooksFeature.State(collection: UserCollection.make()), reducer: {
        CollectionSelectBooksFeature()
    }))
}
