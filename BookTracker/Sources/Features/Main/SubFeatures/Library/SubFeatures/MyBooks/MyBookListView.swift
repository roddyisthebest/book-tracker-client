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
        .background(Color(hex: "#101013", default: .black))
        .navigationTitle("책장")
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
                Picker("정렬", selection: $store.sortOption) {
                    Text("오래된순").tag(BookSortOption.oldest)
                    Text("최신순").tag(BookSortOption.newest)
                    Text("제목순(가나다)").tag(BookSortOption.titleAsc)
                    Text("제목순(반대)").tag(BookSortOption.titleDesc)
                }
                .pickerStyle(.inline)

                Divider()

                Button(role: .destructive, action: {
                    // store.send(.allDeleteButtonTapped)
                }) {
                    Label("전체 삭제", systemImage: "trash")
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
            Picker("탭", selection: $store.bookStatus) {
                Text("완독(\((store.statusCounts?[.done]) ?? 0))").tag(BookStatus.done)
                Text("읽는 중(\((store.statusCounts?[.reading]) ?? 0))").tag(BookStatus.reading)
                Text("읽고 싶은(\((store.statusCounts?[.want]) ?? 0))").tag(BookStatus.want)
                Text("읽다 만(\((store.statusCounts?[.dropped]) ?? 0))").tag(BookStatus.dropped)
            }
            .pickerStyle(.segmented)
            .controlSize(.large)
            .padding(.horizontal)
            .onAppear {
                UISegmentedControl.appearance().selectedSegmentTintColor = UIColor.systemBlue

                let selectedAttrs: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor.white,
                    .font: UIFont.systemFont(ofSize: 14, weight: .bold)
                ]
                let normalAttrs: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor.white.withAlphaComponent(0.8),
                    .font: UIFont.systemFont(ofSize: 14, weight: .medium)
                ]

                UISegmentedControl.appearance().setTitleTextAttributes(normalAttrs, for: .normal)
                UISegmentedControl.appearance().setTitleTextAttributes(selectedAttrs, for: .selected)
            }
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
