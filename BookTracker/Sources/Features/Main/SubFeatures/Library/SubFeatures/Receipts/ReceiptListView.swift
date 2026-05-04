//
//  ReceiptListView.swift
//  BookTracker
//
//  Created by 배성연 on 2/5/26.
//

import ComposableArchitecture
import SwiftUI
import UIKit

struct ReceiptListView: View {
    @Bindable var store: StoreOf<ReceiptListFeature>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .navigationTitle("rental_receipt_slash")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .sheet(item: $store.scope(state: \.receiptDetail, action: \.receiptDetail)) { receiptDetailStore in
            NavigationStack {
                ReceiptDetailView(store: receiptDetailStore)
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .disabled(store.isDeleting)
        .overlay {
            if store.isDeleting {
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
        .animation(.default, value: store.isDeleting)
        .task { await store.send(.onAppear).finish() }
    }

    private static let gridColumns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

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

                Button(role: .destructive, action: { store.send(.allDeleteButtonTapped) }) {
                    Label("delete_all", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack {
            segmentedPicker
            if store.loadingState == .loading && store.list.isEmpty {
                loadingView
            } else if store.loadingState == .error && store.list.isEmpty {
                errorView
            } else if store.list.isEmpty {
                emptyView
            } else {
                grid
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView().tint(.white)
            Text("loading")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.appSecondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var errorView: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.yellow)
            Text("list_load_failed")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.appPrimaryText)
            Text("try_again_later")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.appSecondaryText)
            Button(String(localized: "retry")) {
                store.send(.onRefresh)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 14) {
            Image(systemName: "doc.text")
                .font(.system(size: 28))
                .foregroundStyle(Color.appSecondaryText)
            Text("no_items_to_display")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.appPrimaryText)
            Text("try_other_tab_or_refresh")
                .font(.system(size: 13, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.appSecondaryText)
            Button(String(localized: "refresh")) {
                store.send(.onRefresh)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var segmentedPicker: some View {
        Picker("tab", selection: $store.receiptType) {
            Label("rental_receipt", systemImage: "book").tag(ReceiptType.rental)
            Label("purchase_receipt", systemImage: "doc.text").tag(ReceiptType.purchase)
        }
        .pickerStyle(.segmented)
        .controlSize(.large)
        .padding(.horizontal)
        .padding(.bottom, 10)
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: Self.gridColumns, spacing: 12) {
                ForEach(store.list, id: \.id) { receipt in
                    ReceiptCard(receipt: receipt, onTapped: {
                        store.send(.recepitCardTapped(receipt.type, receipt.id))
                    }, onDelete: {
                        store.send(.deleteButtonTapped(receipt.id))
                    })
                }
                if store.hasMore {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .onAppear { store.send(.loadMore) }
                }
            }
            .padding(.horizontal, 15).padding(.top, 10)
        }
        .refreshable {
            store.send(.onRefresh)
        }
        .overlay(alignment: .bottom) {
            if store.isLoadingMore {
                ProgressView().tint(.white).padding(.vertical, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        ReceiptListView(store: Store(initialState: ReceiptListFeature.State(), reducer: {
            ReceiptListFeature()
        }))
    }
}
