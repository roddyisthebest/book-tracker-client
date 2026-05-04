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
            FormCard(labelText: String(localized: "purchase_place_label")) {
                FormTextField(placeholder: String(localized: "enter_purchase_place"), text: $store.source)
            }
            FormCard(labelText: String(localized: "purchase_date_label")) {
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
            FormCard(labelText: String(localized: "actual_purchase_amount")) {
                FormTextField(placeholder: String(localized: "enter_price_placeholder"), text: $store.price.commaFormatted(), keyboardType: .numberPad)
            }
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appSecondaryText)
                let displayTotal = CurrencyCode.baseUnits(fromMicros: store.totalMicros)
                Text(store.price.isEmpty
                    ? String(format: String(localized: "price_auto_calc %@"), displayTotal.commaFormatted)
                    : String(format: String(localized: "price_with_sum %@ %@"), Int(store.price)?.commaFormatted ?? store.price, displayTotal.commaFormatted))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.appSecondaryText)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        if case .rental = store.type {
            FormCard(labelText: String(localized: "library_label")) {
                FormTextField(placeholder: String(localized: "enter_library"), text: $store.source)
            }
            FormCard(labelText: String(localized: "rental_date_label")) {
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
            .navigationTitle(store.type == .purchase ? "issue_purchase_receipt" : "issue_rental_receipt")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label("back", systemImage: "chevron.left")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if store.isLoading {
                        ProgressView()
                    }
                    else {
                        Button(String(localized: "issue")) {
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
