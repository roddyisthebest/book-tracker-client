//
//  CollectionListView.swift
//  BookTracker
//
//  Created by 배성연 on 2/11/26.
//

import ComposableArchitecture
import SwiftUI
import UIKit

struct CollectionListView: View {
    var store: StoreOf<CollectionListFeature>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#101013", default: .black))
        .navigationTitle("컬렉션")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .task {
            store.send(.onAppear)
        }
        .sheet(
            store: store.scope(
                state: \.$destination.viewCollectionDetail,
                action: \.destination.viewCollectionDetail
            )
        ) { collectionDetailStore in
            CollectionDetailView(store: collectionDetailStore)
        }
        .sheet(
            store: store.scope(
                state: \.$destination.formCollection,
                action: \.destination.formCollection
            )
        ) { formCollectionStore in
            CollectionFormView(store: formCollectionStore)
        }
        .alert(
            store: store.scope(
                state: \.$destination.alert,
                action: \.destination.alert
            )
        )
    }

    private static let gridColumns: [GridItem] = Array(
        repeating: GridItem(.flexible(), spacing: 12),
        count: 2
    )

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("컬렉션 생성하기", systemImage: "books.vertical.circle") {
                    store.send(.addButtonTapped)
                }

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
        Group {
            if store.isLoading && store.collections.isEmpty {
                loadingView
            } else if let errorMessage = store.errorMessage, store.collections.isEmpty {
                errorView(message: errorMessage)
            } else if store.collections.isEmpty {
                emptyView
            } else {
                grid
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: Self.gridColumns, spacing: 12) {
                ForEach(store.collections) { collection in
                    CollectionCard(
                        summary: collection,
                        onTap: {
                            store.send(.collectionCardTapped(collection: collection))
                        },
                        onDelete: {
                            store.send(.deleteButtonTapped(id: collection.id))
                        }
                    )
                    .onAppear {
                        if collection.id == store.collections.last?.id {
                            store.send(.loadMore)
                        }
                    }
                }

                if store.isLoadingMore {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .gridCellColumns(2)
                }
            }
            .padding(.horizontal, 15)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .refreshable {
            store.send(.onRefresh)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("컬렉션을 불러오는 중...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button("다시 시도") {
                store.send(.loadCollections)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "books.vertical")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)

            Text("아직 컬렉션이 없어요")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("새 컬렉션을 만들어 책을 정리해보세요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("컬렉션 생성하기") {
                store.send(.addButtonTapped)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        CollectionListView(
            store: Store(
                initialState: CollectionListFeature.State(
                    collections: [
                        .init(
                            id: UUID(),
                            userId: UUID(),
                            name: "구매한 책",
                            isDefault: false,
                            createdAt: Date(),
                            description: nil,
                            previewBooks: [],
                            bookCount: 0
                        ),
                        .init(
                            id: UUID(),
                            userId: UUID(),
                            name: "읽고 싶은 책",
                            isDefault: false,
                            createdAt: Date(),
                            description: nil,
                            previewBooks: [
                                .init(
                                    id: UUID(),
                                    title: "Book A",
                                    thumbnail: "https://images.unsplash.com/photo-1512820790803-83ca734da794?q=80&w=600&auto=format&fit=crop"
                                ),
                                .init(
                                    id: UUID(),
                                    title: "Book B",
                                    thumbnail: "https://images.unsplash.com/photo-1544947950-fa07a98d237f?q=80&w=600&auto=format&fit=crop"
                                )
                            ],
                            bookCount: 0
                        )
                    ]
                ),
                reducer: {
                    CollectionListFeature()
                }
            )
        )
    }
}
