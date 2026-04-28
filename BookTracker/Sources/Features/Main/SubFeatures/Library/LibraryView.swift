//
//  LibraryView.swift
//  BookTracker
//
//  Created by 배성연 on 2/15/26.
//

import ComposableArchitecture
import SwiftUI

struct LibraryView: View {
    @Bindable var store: StoreOf<LibraryFeature>

    @ViewBuilder
    private var collectionsSectionContent: some View {
        if store.isLoadingCollections {
            ZStack {
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 82.5)

        } else if case .failure = store.collections {
            VStack(alignment: .leading, spacing: 8) {
                Text("collection_load_failed")
                    .font(.footnote)
                    .foregroundStyle(.red.opacity(0.8))

                Button(action: { store.send(.loadCollections) }) {
                    Text("retry")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 82.5)
            .padding(.horizontal)

        } else if let collections = try? store.collections.get(), !collections.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(collections, id: \.id) { collection in
                        CollectionCard(
                            summary: collection,
                            onTap: {
                                store.send(.collectionCardTapped(collection: collection))
                            },
                            onDelete: {
                                store.send(.deleteCollectionButtonTapped(id: collection.id))
                            }
                        )
                        .frame(width: 150)
                    }
                }
                .padding(.leading)
            }
            .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 10) {
                Image(systemName: "square.stack")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.appSecondaryText.opacity(0.6))
                Text("no_collections_yet")
                    .font(.footnote)
                    .foregroundStyle(Color.appSecondaryText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 82.5)
        }
    }

    @ViewBuilder
    private var statusCountsContent: some View {
        if store.isLoadingStatusCounts {
            ZStack {
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 82.5)

        } else if case .failure = store.statusCounts {
            VStack(alignment: .leading, spacing: 8) {
                Text("status_count_load_failed")
                    .font(.footnote)
                    .foregroundStyle(.red.opacity(0.8))

                Button(action: { store.send(.loadStatusCounts) }) {
                    Text("retry")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 82.5)
            .padding(.horizontal)

        } else if let counts = try? store.statusCounts.get() {
            HStack(spacing: 12) {
                Button(action: {
                    store.send(.sectionTapped(.myBooks(status: .done)))
                }) {
                    VStack(spacing: 6) {
                        Text("\(counts[.done] ?? 0)")
                            .font(.system(size: 20, weight: .bold))
                        Text("status_done")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 70)
                    .background(Color.appSurface)
                    .cornerRadius(10)
                    .foregroundStyle(Color.appSecondaryText)
                }

                Button(action: {
                    store.send(.sectionTapped(.myBooks(status: .reading)))
                }) {
                    VStack(spacing: 6) {
                        Text("\(counts[.reading] ?? 0)")
                            .font(.system(size: 20, weight: .bold))
                        Text("status_reading")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 70)
                    .background(Color.appSurface)
                    .cornerRadius(10)
                    .foregroundStyle(Color.appSecondaryText)
                }

                Button(action: {
                    store.send(.sectionTapped(.myBooks(status: .want)))
                }) {
                    VStack(spacing: 6) {
                        Text("\(counts[.want] ?? 0)")
                            .font(.system(size: 20, weight: .bold))
                        Text("status_want")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 70)
                    .background(Color.appSurface)
                    .cornerRadius(10)
                    .foregroundStyle(Color.appSecondaryText)
                }

                Button(action: {
                    store.send(.sectionTapped(.myBooks(status: .dropped)))
                }) {
                    VStack(spacing: 6) {
                        Text("\(counts[.dropped] ?? 0)")
                            .font(.system(size: 20, weight: .bold))
                        Text("status_dropped")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 70)
                    .background(Color.appSurface)
                    .cornerRadius(10)
                    .foregroundStyle(Color.appSecondaryText)
                }
            }
            .frame(maxWidth: .infinity)

        } else {
            EmptyView()
        }
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 15) {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("view_my_bookshelf").font(.title2).fontWeight(.bold).foregroundStyle(Color.appPrimaryText)
                            Spacer()
                            Button(action: {
                                store.send(.sectionTapped(.myBooks(status: .done)))
                            }) {
                                Text("view_all")
                                Image(systemName: "chevron.right")
                            }.fontWeight(.semibold).foregroundStyle(Color.appSecondaryText).font(.system(size: 16))
                        }
                        Text("library_status_description").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.appSecondaryText)
                        // Loading/Error/Success handled below
                    }

                    statusCountsContent
                }.padding()

                Rectangle().fill(Color.appSurfaceDeeper).frame(height: 15)

                VStack(spacing: 20) {
                    HStack {
                        Text("collections").font(.title2).fontWeight(.bold).foregroundStyle(Color.appPrimaryText)
                        Spacer()
                        Button(action: {
                            store.send(.sectionTapped(.collections))
                        }) {
                            Text("view_all")
                            Image(systemName: "chevron.right")
                        }.fontWeight(.semibold).foregroundStyle(Color.appSecondaryText).font(.system(size: 16))
                    }.padding(.top).padding(.horizontal)

                    collectionsSectionContent
                }
                .padding(.bottom)
                Rectangle().fill(Color.appSurfaceDeeper).frame(height: 15)

                VStack(spacing: 20) {
                    HStack {
                        Text("rental_receipt_slash").font(.title2).fontWeight(.bold).foregroundStyle(Color.appPrimaryText)
                        Spacer()
                        Button(action: {
                            store.send(.sectionTapped(.receipts))
                        }) {
                            Text("view_all")
                            Image(systemName: "chevron.right")
                        }.fontWeight(.semibold).foregroundStyle(Color.appSecondaryText).font(.system(size: 16))
                    }.padding(.top).padding(.horizontal)

                    if store.isLoadingRecentReceipts {
                        ZStack {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                    } else if case .failure = store.recentReceipts {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("receipt_load_failed")
                                .font(.footnote)
                                .foregroundStyle(.red.opacity(0.8))

                            Button(action: { store.send(.loadRecentReceipts) }) {
                                Text("retry")
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    } else if let receipts = try? store.recentReceipts.get(), !receipts.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 12) {
                                ForEach(receipts, id: \.id) { receipt in
                                    ReceiptCard(
                                        receipt: receipt,
                                        onTapped: { store.send(.receiptCardTapped(id: receipt.id)) },
                                        onDelete: { store.send(.deleteReceiptButtonTapped(id: receipt.id)) }
                                    )
                                    .frame(width: 170)
                                }
                            }
                            .padding(.leading)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 24))
                                .foregroundStyle(Color.appSecondaryText.opacity(0.6))
                            Text("no_items_to_display")
                                .font(.footnote)
                                .foregroundStyle(Color.appSecondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                    }
                }.padding(.bottom, 24)
            }
        }
        .background(Color.appBackground)
    }

    @ViewBuilder
    private func destinationView(for destinationStore: StoreOf<LibraryFeature.Path>) -> some View {
        switch destinationStore.state {
        case .myBooks:
            if let store = destinationStore.scope(state: \.myBooks, action: \.myBooks) {
                MyBookListView(store: store)
            }
        case .receipts:
            if let store = destinationStore.scope(state: \.receipts, action: \.receipts) {
                ReceiptListView(store: store)
            }
        case .collections:
            if let store = destinationStore.scope(state: \.collections, action: \.collections) {
                CollectionListView(store: store)
            }
        }
    }

    var body: some View {
        NavigationStackStore(store.scope(state: \.path, action: \.path)) {
            mainContent
        } destination: { destinationStore in
            destinationView(for: destinationStore)
        }
        .task { await store.send(.onAppear).finish() }
        .sheet(store: store.scope(state: \.$destination.collectionDetail, action: \.destination.collectionDetail)) { collectionDetailStore in
            CollectionDetailView(store: collectionDetailStore)
        }
        .sheet(store: store.scope(state: \.$destination.receiptDetail, action: \.destination.receiptDetail)) { receiptDetailStore in
            ReceiptDetailView(store: receiptDetailStore)
        }
        .alert(
            store: store.scope(
                state: \.$destination.alert,
                action: \.destination.alert
            )
        )
        .navigationTitle("library")
        .navigationBarTitleDisplayMode(.inline)
        .disabled(store.isDeletingCollection || store.isDeletingReceipt)
        .overlay {
            if store.isDeletingCollection || store.isDeletingReceipt {
                ZStack {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.1)
                        .padding(16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .transition(.opacity)
            }
        }
        .animation(.default, value: store.isDeletingCollection)
        .animation(.default, value: store.isDeletingReceipt)
    }
}

#Preview {
    NavigationStack {
        LibraryView(store: Store(initialState: LibraryFeature.State(), reducer: {
            LibraryFeature()
        }))
    }
}
