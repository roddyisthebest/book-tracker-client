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

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 15) {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("내 책장 보기").font(.title2).fontWeight(.bold)
                            Spacer()
                            Button(action: {
                                store.send(.sectionTapped(.myBooks(status: .done)))
                            }) {
                                Text("전체보기")
                                Image(systemName: "chevron.right")
                            }.fontWeight(.semibold).foregroundStyle(Color(hex: "#62626D", default: .gray)).font(.system(size: 16))
                        }
                        Text("독서 상태별로 책을 한눈에 볼 수 있어요").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color(hex: "#7E7E87", default: .gray))
                        // Loading/Error/Success handled below
                    }

                    // Mutually exclusive rendering: loading, error, or success
                    Group {
                        if store.isLoadingStatusCounts {
                            ZStack {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .tint(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 82.5)
                        } else if case .failure = store.statusCounts {
                            ZStack(alignment: .leading) {
                                Text("상태 카운트를 불러오지 못했어요")
                                    .font(.footnote)
                                    .foregroundStyle(.red.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 82.5)
                        } else if let counts = try? store.statusCounts.get() {
                            HStack(spacing: 12) {
                                Button(action: { store.send(.sectionTapped(.myBooks(status: .done))) }) {
                                    VStack(spacing: 10) {
                                        Image(systemName: "book.pages.fill")
                                        Text("완독 \(counts[.done] ?? 0)").font(.subheadline)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 82.5)
                                    .background(Color(hex: "#2C2C35", default: .gray))
                                    .cornerRadius(10)
                                    .foregroundStyle(Color(hex: "#C0C0CF", default: .white))
                                }
                                Button(action: { store.send(.sectionTapped(.myBooks(status: .reading))) }) {
                                    VStack(spacing: 10) {
                                        Image(systemName: "book.pages.fill")
                                        Text("읽는 중 \(counts[.reading] ?? 0)").font(.subheadline)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 82.5)
                                    .background(Color(hex: "#2C2C35", default: .gray))
                                    .cornerRadius(10)
                                    .foregroundStyle(Color(hex: "#C0C0CF", default: .white))
                                }
                                Button(action: { store.send(.sectionTapped(.myBooks(status: .want))) }) {
                                    VStack(spacing: 10) {
                                        Image(systemName: "book.pages.fill")
                                        Text("읽고싶은 \(counts[.want] ?? 0)").font(.subheadline)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 82.5)
                                    .background(Color(hex: "#2C2C35", default: .gray))
                                    .cornerRadius(10)
                                    .foregroundStyle(Color(hex: "#C0C0CF", default: .white))
                                }
                                Button(action: { store.send(.sectionTapped(.myBooks(status: .dropped))) }) {
                                    VStack(spacing: 10) {
                                        Image(systemName: "book.pages.fill")
                                        Text("읽다 만 \(counts[.dropped] ?? 0)").font(.subheadline)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 82.5)
                                    .background(Color(hex: "#2C2C35", default: .gray))
                                    .cornerRadius(10)
                                    .foregroundStyle(Color(hex: "#C0C0CF", default: .white))
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }

                }.padding()

                Divider().frame(height: 15).background(.black)

                VStack(spacing: 20) {
                    HStack {
                        Text("컬렉션").font(.title2).fontWeight(.bold)
                        Spacer()
                        Button(action: {
                            store.send(.sectionTapped(.collections))
                        }) {
                            Text("전체보기")
                            Image(systemName: "chevron.right")
                        }.fontWeight(.semibold).foregroundStyle(Color(hex: "#62626D", default: .gray)).font(.system(size: 16))
                    }.padding(.top).padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 12) {
                            // 예시: 여러 개의 카드가 있다고 가정
                            ForEach(store.collections, id: \.id) {
                                collection in
                                CollectionCard(onTap: {
                                    store.send(.collectionCardTapped(id: collection.id))
                                }, onDelete: {}).frame(minWidth: 150)
                            }
                        }
                    }
                    .padding(.leading)
                    .frame(maxWidth: .infinity)
                }
                .padding(.bottom)
                Divider().frame(height: 15).background(.black)

                VStack(spacing: 20) {
                    HStack {
                        Text("대출증/영수증").font(.title2).fontWeight(.bold)
                        Spacer()
                        Button(action: {
                            store.send(.sectionTapped(.receipts))
                        }) {
                            Text("전체보기")
                            Image(systemName: "chevron.right")
                        }.fontWeight(.semibold).foregroundStyle(Color(hex: "#62626D", default: .gray)).font(.system(size: 16))
                    }.padding(.top).padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 12) {
                            // 예시: 여러 개의 카드가 있다고 가정
                            ForEach(store.receipts, id: \.id) {
                                receipt in
                                ReceiptCard(receipt: receipt, onTapped: {
                                    store.send(.receiptCardTapped(id: receipt.id))
                                }, onDelete: {}).frame(width: 170)
                            }
                        }
                    }
                    .padding(.leading)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .background(Color(hex: "#101013", default: .black))
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
        .task { await store.send(.loadStatusCounts).finish() }
        .sheet(store: store.scope(state: \.$destination.collectionDetail, action: \.destination.collectionDetail)) { collectionDetailStore in
            CollectionDetailView(store: collectionDetailStore)
        }
        .sheet(store: store.scope(state: \.$destination.receiptDetail, action: \.destination.receiptDetail)) { receiptDetailStore in
            ReceiptDetailView(store: receiptDetailStore)
        }
        .navigationTitle("서재")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LibraryView(store: Store(initialState: LibraryFeature.State(), reducer: {
            LibraryFeature()
        }))
    }
}
