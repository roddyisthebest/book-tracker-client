//
//  IssueReceiptView.swift
//  BookTracker
//
//  Created by 배성연 on 2/20/26.
//

import ComposableArchitecture
import SwiftUI

struct IssueReceiptView: View {
    @Bindable var store: StoreOf<IssueReceiptFeature>
    @Environment(\.dismiss) private var dismiss

    @ViewBuilder
    private var typeSpecific: some View {
        if case .purchase = store.type {
            FormCard(labelText: "구매처") {
                FormTextField(placeholder: "구매처를 입력해주세요", text: $store.source)
            }
            FormCard(labelText: "구매날짜") {
                DatePicker(
                    "",
                    selection: $store.receiptAt,
                    in: ...Date(),
                    displayedComponents: [.date]
                )
                .labelsHidden()
                .datePickerStyle(.graphical)
                .tint(Color.appAccent)
                .padding(8)
                .background(Color.appSurfaceDeep)
                .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            FormCard(labelText: "실제 구매 금액") {
                FormTextField(placeholder: "23,000원", text: $store.price, keyboardType: .numberPad)
            }
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appSecondaryText)
                Text(store.price.isEmpty
                     ? "미입력 시 책 가격 합산(\(store.totalPrice)원)으로 자동 계산돼요"
                     : "총 계산된 금액: \(store.price)원 (책 가격 합산: \(store.totalPrice)원)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.appSecondaryText)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        if case .rental = store.type {
            FormCard(labelText: "도서관") {
                FormTextField(placeholder: "도서관을 입력해주세요", text: $store.source)
            }
            FormCard(labelText: "대출날짜") {
                DatePicker(
                    "",
                    selection: $store.receiptAt,
                    in: ...Date(),
                    displayedComponents: [.date]
                )
                .labelsHidden()
                .datePickerStyle(.graphical)
                .tint(Color.appAccent)
                .padding(8)
                .background(Color.appSurfaceDeep)
                .clipShape(RoundedRectangle(cornerRadius: 15))
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                typeSpecific
            }
            .listStyle(.plain)
            .padding(0)
            .listStyle(.insetGrouped)
            .navigationTitle(store.type == .purchase ? "영수증 발급" : "대출증 발급")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label("뒤로가기", systemImage: "chevron.left")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if store.isLoading {
                        ProgressView()
                    }
                    else {
                        Button("발급하기") {
                            store.send(.issueButtonTapped)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden) // 추가
            .background(Color.appSurface)
        }
        .alert($store.scope(state: \.alert, action: \.alert))
    }
}

#Preview {
    IssueReceiptView(
        store: Store(
            initialState: IssueReceiptFeature.State(),
            reducer: { IssueReceiptFeature() }
        )
    )
}
