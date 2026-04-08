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
                Text("컬렉션 목록을 불러오지 못했어요")
                    .font(.footnote)
                    .foregroundStyle(.red.opacity(0.8))

                Button(action: { store.send(.loadCollections) }) {
                    Text("다시 가져오기")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 82.5)
            .padding(.horizontal)

        } else if let collections = try? store.collections.get() {
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
            EmptyView()
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
                Text("상태 카운트를 불러오지 못했어요")
                    .font(.footnote)
                    .foregroundStyle(.red.opacity(0.8))

                Button(action: { store.send(.loadStatusCounts) }) {
                    Text("다시 가져오기")
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
                    VStack(spacing: 10) {
                        Image(systemName: "book.pages.fill")
                        Text("완독 \(counts[.done] ?? 0)")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 82.5)
                    .background(Color.appSurface)
                    .cornerRadius(10)
                    .foregroundStyle(Color.appSecondaryText)
                }

                Button(action: {
                    store.send(.sectionTapped(.myBooks(status: .reading)))
                }) {
                    VStack(spacing: 10) {
                        Image(systemName: "book.pages.fill")
                        Text("읽는 중 \(counts[.reading] ?? 0)")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 82.5)
                    .background(Color.appSurface)
                    .cornerRadius(10)
                    .foregroundStyle(Color.appSecondaryText)
                }

                Button(action: {
                    store.send(.sectionTapped(.myBooks(status: .want)))
                }) {
                    VStack(spacing: 10) {
                        Image(systemName: "book.pages.fill")
                        Text("읽고싶은 \(counts[.want] ?? 0)")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 82.5)
                    .background(Color.appSurface)
                    .cornerRadius(10)
                    .foregroundStyle(Color.appSecondaryText)
                }

                Button(action: {
                    store.send(.sectionTapped(.myBooks(status: .dropped)))
                }) {
                    VStack(spacing: 10) {
                        Image(systemName: "book.pages.fill")
                        Text("읽다 만 \(counts[.dropped] ?? 0)")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 82.5)
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
                            Text("내 책장 보기").font(.title2).fontWeight(.bold).foregroundStyle(Color.appPrimaryText)
                            Spacer()
                            Button(action: {
                                store.send(.sectionTapped(.myBooks(status: .done)))
                            }) {
                                Text("전체보기")
                                Image(systemName: "chevron.right")
                            }.fontWeight(.semibold).foregroundStyle(Color.appSecondaryText).font(.system(size: 16))
                        }
                        Text("독서 상태별로 책을 한눈에 볼 수 있어요").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.appSecondaryText)
                        // Loading/Error/Success handled below
                    }

                    statusCountsContent
                }.padding()

                Rectangle().fill(Color.appSurfaceDeeper).frame(height: 15)

                VStack(spacing: 20) {
                    HStack {
                        Text("컬렉션").font(.title2).fontWeight(.bold).foregroundStyle(Color.appPrimaryText)
                        Spacer()
                        Button(action: {
                            store.send(.sectionTapped(.collections))
                        }) {
                            Text("전체보기")
                            Image(systemName: "chevron.right")
                        }.fontWeight(.semibold).foregroundStyle(Color.appSecondaryText).font(.system(size: 16))
                    }.padding(.top).padding(.horizontal)

                    collectionsSectionContent
                }
                .padding(.bottom)
                Rectangle().fill(Color.appSurfaceDeeper).frame(height: 15)

                VStack(spacing: 20) {
                    HStack {
                        Text("대출증/영수증").font(.title2).fontWeight(.bold).foregroundStyle(Color.appPrimaryText)
                        Spacer()
                        Button(action: {
                            store.send(.sectionTapped(.receipts))
                        }) {
                            Text("전체보기")
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
                            Text("대출증/영수증을 불러오지 못했어요")
                                .font(.footnote)
                                .foregroundStyle(.red.opacity(0.8))

                            Button(action: { store.send(.loadRecentReceipts) }) {
                                Text("다시 가져오기")
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
                                        onDelete: {}
                                    )
                                    .frame(width: 170)
                                }
                            }
                            .padding(.leading)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Text("표시할 항목이 없어요")
                            .font(.footnote)
                            .foregroundStyle(Color.appSecondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
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
        .navigationTitle("서재")
        .navigationBarTitleDisplayMode(.inline)
        .disabled(store.isDeletingCollection)
        .overlay {
            if store.isDeletingCollection {
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
    }
}

#Preview {
    NavigationStack {
        LibraryView(store: Store(initialState: LibraryFeature.State(), reducer: {
            LibraryFeature()
        }))
    }
}
