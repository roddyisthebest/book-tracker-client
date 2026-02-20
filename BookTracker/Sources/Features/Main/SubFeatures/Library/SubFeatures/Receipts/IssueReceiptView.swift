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
                FormTextField(placeholder: "구매처를 입력해주세요", text: $store.storeName)
            }
            FormCard(labelText: "구매날짜") {
                DatePicker(
                    "",
                    selection: $store.payedAt,
                    in: ...Date(),
                    displayedComponents: [.date]
                )
                .labelsHidden()
                .datePickerStyle(.graphical)
                .tint(.white)
                .padding(8)
                .background(Color(hex: "#17171C", default: .accentColor))
                .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            FormCard(labelText: "실제 구매 금액") {
                FormTextField(placeholder: "23,000원", text: $store.price, keyboardType: .numberPad)
            }
        }
        if case .rental = store.type {
            FormCard(labelText: "도서관") {
                FormTextField(placeholder: "도서관을 입력해주세요", text: $store.libraryName)
            }
            FormCard(labelText: "대출날짜") {
                DatePicker(
                    "",
                    selection: $store.borrowedAt,
                    in: ...Date(),
                    displayedComponents: [.date]
                )
                .labelsHidden()
                .datePickerStyle(.graphical)
                .tint(.white)
                .padding(8)
                .background(Color(hex: "#17171C", default: .accentColor))
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
                    Button("발급하기") {
                        store.send(.issueButtonTapped)
                    }
                }
            }
            .scrollContentBackground(.hidden) // 추가
            .background(Color(hex: "#2C2C35", default: .black))
        }
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
