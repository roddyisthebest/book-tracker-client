//
//  ReceiptDetailView.swift
//  BookTracker
//
//  Created by 배성연 on 2/3/26.
//

import ComposableArchitecture
import SwiftUI

struct ReceiptDetailView: View {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    @Bindable var store: StoreOf<ReceiptDetailFeature>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 0) {
                        if store.isLoading && store.detail == nil && !store.isError {
                            VStack(spacing: 14) {
                                ProgressView().tint(.white)
                                Text("loading")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.appSecondaryText)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.vertical, 40)
                        } else if store.isError {
                            VStack(spacing: 14) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.yellow)
                                Text("detail_load_failed")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color.appPrimaryText)
                                Button(action: { store.send(.onRefresh) }) {
                                    Text("retry")
                                        .font(.system(size: 14, weight: .semibold))
                                        .frame(maxWidth: 180)
                                        .padding(.vertical, 12)
                                        .background(Color.white)
                                        .foregroundStyle(.black)
                                        .cornerRadius(10)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.vertical, 40)
                        } else if let detail = store.detail {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                ForEach(Array(detail.items.enumerated()), id: \.offset) { idx, item in
                                    ReceiptRow(idx: idx, type: detail.type, item: item)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)

                            Divider().background(Color.appSeparator)
                            HStack {
                                Spacer()
                                Text("total_books \(detail.items.count)").foregroundStyle(Color.appPrimaryText).font(.headline)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            Rectangle().fill(Color.appSurfaceDeeper).frame(height: 15)

                            VStack {
                                HStack {
                                    Text("status_value").foregroundStyle(Color.appPrimaryText).font(.system(size: 25)).fontWeight(.black)
                                    Spacer()
                                }
                                .padding(.top, 5)
                                VStack(spacing: 17.5) {
                                    StatusRow(key: (detail.type == .rental ? String(localized: "rental_date_key") : String(localized: "purchase_date_key")), value: detail.receiptAt.map { Self.dateFormatter.string(from: $0) } ?? "-")
                                    StatusRow(key: detail.type == .rental ? String(localized: "library_label") : String(localized: "purchase_place_label"), value: detail.source)
                                    if let price = detail.totalPrice, detail.type == .purchase {
                                        StatusRow(key: String(localized: "amount_label"), value: (Self.numberFormatter.string(from: NSNumber(value: price)) ?? "\(price)") + String(localized: "won_unit"))
                                    }
                                }
                                .padding(.vertical, 10)
                                .padding(.bottom, 80)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical)
                        }
                    }
                    .refreshable {
                        store.send(.onRefresh)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appSurface)
            .navigationTitle("purchase_receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label("back", systemImage: "chevron.left")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        store.send(.deleteButtonTapped)
                    } label: {
                        Label("delete", systemImage: "trash")
                    }
                }
            }
            .alert($store.scope(state: \.alert, action: \.alert))
            .task {
                await store.send(.onAppear).finish()
            }
        }
    }
}

#Preview {
    ReceiptDetailView(store: Store(initialState: ReceiptDetailFeature.State(id: UUID(1)), reducer: {
        ReceiptDetailFeature()
    }))
}

