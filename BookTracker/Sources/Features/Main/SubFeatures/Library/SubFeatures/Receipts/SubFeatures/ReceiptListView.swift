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
            header
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#101013", default: .black))
        .sheet(item: $store.scope(state: \.receiptDetail, action: \.receiptDetail)) { receiptDetailStore in
            NavigationStack {
                ReceiptDetailView(store: receiptDetailStore)
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
    }

    private static let gridColumns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

    private var header: some View {
        ZStack {
            Text("대출증/영수증")
                .font(.headline)
                .foregroundStyle(.white)

            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Spacer()
                Menu {
                    Picker("정렬", selection: $store.sortOption) {
                        Text("오래된순").tag(ReceiptListFeature.SortOption.oldest)
                        Text("최신순").tag(ReceiptListFeature.SortOption.newest)
                        Text("제목순(가나다)").tag(ReceiptListFeature.SortOption.titleAsc)
                        Text("제목순(반대)").tag(ReceiptListFeature.SortOption.titleDesc)
                    }
                    .pickerStyle(.inline)

                    Divider()

                    Button(role: .destructive, action: { store.send(.allDeleteButtonTapped) }) {
                        Label("전체 삭제", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(height: 52)
        .padding(.horizontal)
    }

    private var content: some View {
        VStack {
            segmentedPicker
            grid
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var segmentedPicker: some View {
        Picker("탭", selection: $store.receiptType) {
            Label("대출증(10)", systemImage: "book").tag(ReceiptType.rental)
            Label("영수증(5)", systemImage: "doc.text").tag(ReceiptType.purchase)
        }
        .pickerStyle(.segmented)
        .controlSize(.large)
        .padding(.horizontal)
        .onAppear {
            // 선택된 세그먼트의 pill 배경색
            UISegmentedControl.appearance().selectedSegmentTintColor = UIColor.systemBlue

            // (옵션) 텍스트 색상/두께/크기 조절
            let selectedAttrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 17, weight: .bold)
            ]
            let normalAttrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white.withAlphaComponent(0.8),
                .font: UIFont.systemFont(ofSize: 17, weight: .medium)
            ]
            UISegmentedControl.appearance().setTitleTextAttributes(normalAttrs, for: .normal)
            UISegmentedControl.appearance().setTitleTextAttributes(selectedAttrs, for: .selected)
        }
        .onDisappear {
            // 필요 시 원복 (전역 Appearance 영향 최소화)
            UISegmentedControl.appearance().selectedSegmentTintColor = nil
            UISegmentedControl.appearance().setTitleTextAttributes(nil, for: .normal)
            UISegmentedControl.appearance().setTitleTextAttributes(nil, for: .selected)
        }
        .padding(.bottom, 10)
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: Self.gridColumns, spacing: 12) {
                ForEach(store.computedList.indices, id: \.self) { index in
                    let receipt = store.computedList[index]
                    ReceiptCard(receipt: store.computedList[index], onTapped: {
                        store.send(.recepitCardTapped(receipt.type, receipt.id))
                    }, onDelete: {
                        store.send(.deleteButtonTapped(receipt.id))
                    })
                }
            }
            .padding(.horizontal, 15).padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ReceiptListView(store: Store(initialState: ReceiptListFeature.State(), reducer: {
        ReceiptListFeature()
    }))
}
