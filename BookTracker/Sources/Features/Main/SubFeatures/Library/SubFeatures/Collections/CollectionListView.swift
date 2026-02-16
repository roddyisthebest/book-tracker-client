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
        .sheet(store: store.scope(state: \.$destination.viewCollectionDetail, action: \.destination.viewCollectionDetail)) {
            collectionDetailStore in
            CollectionDetailView(store: collectionDetailStore)
        }
        .sheet(store: store.scope(state: \.$destination.formCollection, action: \.destination.formCollection)) {
            formCollectionStore in
            CollectionFormView(store: formCollectionStore)
        }
        .alert(store: store.scope(state: \.$destination.alert, action: \.destination.alert))
    }

    private static let gridColumns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
//                Picker("정렬", selection: $store.sortOption) {
//                    Text("오래된순").tag(BookSortOption.oldest)
//                    Text("최신순").tag(BookSortOption.newest)
//                    Text("제목순(가나다)").tag(BookSortOption.titleAsc)
//                    Text("제목순(반대)").tag(BookSortOption.titleDesc)
//                }
//                .pickerStyle(.inline)
//
//                Divider()

                Button("컬렉션 생성하기", systemImage: "books.vertical.circle") {
                    store.send(.addButtonTapped)
                }
                Button(role: .destructive, action: {
//                    store.send(.allDeleteButtonTapped)
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
            grid
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: Self.gridColumns, spacing: 12) {
                ForEach(store.collections.indices, id: \.self) { index in
                    let collection = store.collections[index]
                    CollectionCard(onTap: {
                        store.send(.collectionCardTapped(id: collection.id))
                    }, onDelete: {
                        store.send(.deleteButtonTapped(id: collection.id))
                    })
                }
            }
            .padding(.horizontal, 15).padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        CollectionListView(store: Store(initialState: CollectionListFeature.State(), reducer: {
            CollectionListFeature()
        }))
    }
}
