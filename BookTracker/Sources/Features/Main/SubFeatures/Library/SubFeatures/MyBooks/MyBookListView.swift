//
//  MyBookList.swift
//  BookTracker
//
//  Created by 배성연 on 2/15/26.
//

import ComposableArchitecture
import SwiftUI

struct MyBookListView: View {
    @Bindable var store: StoreOf<MyBookListFeature>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                content
            }

            if store.isDeleting {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .disabled(store.isDeleting)
        .animation(.easeInOut, value: store.isDeleting)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .navigationTitle("bookshelf")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .sheet(store: store.scope(state: \.$destination.viewBookDetail, action: \.destination.viewBookDetail)) { bookDetailStore in
            BookDetailView(store: bookDetailStore)
        }
        .alert(store: store.scope(state: \.$destination.alert, action: \.destination.alert))
        .task {
            await store.send(.onAppear).finish()
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("sort", selection: $store.sortOption) {
                    Text("sort_oldest").tag(BookSortOption.oldest)
                    Text("sort_newest").tag(BookSortOption.newest)
                    Text("sort_title_asc").tag(BookSortOption.titleAsc)
                    Text("sort_title_desc").tag(BookSortOption.titleDesc)
                }
                .pickerStyle(.inline)

                Divider()

                Button(role: .destructive, action: {
                    // store.send(.allDeleteButtonTapped)
                }) {
                    Label("delete_all", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    private var content: some View {
        VStack {
            segmentedPicker
            list
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var segmentedPicker: some View {
        if store.isLoadingStatusCounts {
            ZStack {
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)

        } else {
            Picker("tab", selection: $store.bookStatus) {
                Text("\(String(localized: "status_done")) (\((store.statusCounts?[.done]) ?? 0))").tag(BookStatus.done)
                Text("\(String(localized: "status_reading")) (\((store.statusCounts?[.reading]) ?? 0))").tag(BookStatus.reading)
                Text("\(String(localized: "status_want")) (\((store.statusCounts?[.want]) ?? 0))").tag(BookStatus.want)
                Text("\(String(localized: "status_dropped")) (\((store.statusCounts?[.dropped]) ?? 0))").tag(BookStatus.dropped)
            }
            .pickerStyle(.segmented)
            .controlSize(.large)
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
    }

    private var list: some View {
        ZStack {
            ScrollView {
                LazyVStack {
                    ForEach(store.books, id: \.id) { book in
                        BookRow(
                            book: book,
                            onTap: {
                                store.send(.bookCardTapped(id: book.id))
                            },
                            onDelete: {
                                store.send(.deleteButtonTapped(id: book.id))
                            }
                        )
                        .onAppear {
                            if book.id == store.books.last?.id {
                                store.send(.loadMore)
                            }
                        }
                    }

                    if store.isLoadingMore {
                        ProgressView()
                            .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, 15)
                .padding(.top, 10)
            }
            .allowsHitTesting(!(store.isLoading && store.books.isEmpty))

            if store.isLoading && store.books.isEmpty {
                ProgressView()
                    .scaleEffect(1.1)
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .refreshable {
            await store.send(.refresh).finish()
        }
    }
}

#Preview {
    MyBookListView(
        store: Store(
            initialState: MyBookListFeature.State(),
            reducer: {
                MyBookListFeature()
            }
        )
    )
}
