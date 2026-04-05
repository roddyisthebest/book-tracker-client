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
        .navigationTitle("대출증/영수증")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .sheet(item: $store.scope(state: \.receiptDetail, action: \.receiptDetail)) { receiptDetailStore in
            NavigationStack {
                ReceiptDetailView(store: receiptDetailStore)
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .task { await store.send(.onAppear).finish() }
    }

    private static let gridColumns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

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

                Button(role: .destructive, action: { store.send(.allDeleteButtonTapped) }) {
                    Label("전체 삭제", systemImage: "trash")
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
            if store.isLoading && store.list.isEmpty && !store.isError {
                loadingView
            } else if store.isError && store.list.isEmpty {
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
            Text("불러오는 중이에요...")
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
            Text("목록을 불러오지 못했어요.")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.appPrimaryText)
            Text("잠시 후 다시 시도해주세요.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.appSecondaryText)
            Button(action: { store.send(.onRefresh) }) {
                Text("다시 시도")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: 180)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .foregroundStyle(.black)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 14) {
            Image(systemName: "doc.text")
                .font(.system(size: 28))
                .foregroundStyle(Color.appSecondaryText)
            Text("표시할 항목이 없어요.")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.appPrimaryText)
            Text("다른 탭을 선택하거나 새로고침 해보세요.")
                .font(.system(size: 13, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.appSecondaryText)
            Button(action: { store.send(.onRefresh) }) {
                Text("새로고침")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: 180)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .foregroundStyle(.black)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var segmentedPicker: some View {
        Picker("탭", selection: $store.receiptType) {
            Label("대출증", systemImage: "book").tag(ReceiptType.rental)
            Label("영수증", systemImage: "doc.text").tag(ReceiptType.purchase)
        }
        .pickerStyle(.segmented)
        .controlSize(.large)
        .padding(.horizontal)
        .onAppear {
            UISegmentedControl.appearance().selectedSegmentTintColor = UIColor.systemBlue

            let selectedAttrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 16, weight: .bold)
            ]
            let normalAttrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white.withAlphaComponent(0.8),
                .font: UIFont.systemFont(ofSize: 16, weight: .medium)
            ]

            UISegmentedControl.appearance().setTitleTextAttributes(normalAttrs, for: .normal)
            UISegmentedControl.appearance().setTitleTextAttributes(selectedAttrs, for: .selected)
        }

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
