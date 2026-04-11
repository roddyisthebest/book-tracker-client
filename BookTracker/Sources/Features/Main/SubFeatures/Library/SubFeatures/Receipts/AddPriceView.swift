//
//  AddPriceView.swift
//  BookTracker
//
//  Created by 배성연 on 3/29/26.
//

import ComposableArchitecture
import SwiftUI

struct AddPriceView: View {
    @Bindable var store: StoreOf<AddPriceFeature>
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isPriceFieldFocused: Bool

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("price")
                        .foregroundStyle(.blue)
                        .font(.caption)

                    VStack(spacing: 7) {
                        HStack(spacing: 10) {
                            TextField(
                                "",
                                text: priceBinding,
                                prompt: Text("enter_price").foregroundStyle(Color.appSecondaryText)
                            )
                            .keyboardType(.numberPad)
                            .foregroundStyle(Color.appPrimaryText)
                            .font(.system(size: 20, weight: .semibold))
                            .background(.clear)
                            .frame(height: 28)
                            .focused($isPriceFieldFocused)

                            Text(store.currencyCode.rawValue)
                                .foregroundStyle(Color.appSecondaryText)
                                .font(.system(size: 16, weight: .semibold))
                        }

                        Color.blue.frame(height: 1)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("currency_code")
                        .foregroundStyle(.blue)
                        .font(.caption)

                    Menu {
                        ForEach(CurrencyCode.allCases, id: \.self) { code in
                            Button(code.rawValue) {
                                store.send(.binding(.set(\.currencyCode, code)))
                            }
                        }
                    } label: {
                        HStack {
                            Text(store.currencyCode.rawValue)
                                .foregroundStyle(Color.appPrimaryText)
                                .font(.system(size: 18, weight: .semibold))

                            Spacer()

                            Text(store.currencyCode.description)
                                .foregroundStyle(Color.appSecondaryText)
                                .font(.system(size: 13, weight: .medium))

                            Image(systemName: "chevron.up.chevron.down")
                                .foregroundStyle(Color.appSecondaryText)
                        }
                        .padding(.vertical, 10)
                    }

                    Color.blue.frame(height: 1)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("preview")
                        .foregroundStyle(.blue)
                        .font(.caption)

                    HStack {
                        Text(formattedPreviewPrice)
                            .foregroundStyle(Color.appPrimaryText)
                            .font(.system(size: 22, weight: .bold))

                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .padding(0)
        .navigationTitle("add_receipt_price")
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
                Button {
                    store.send(.addButtonTapped)
                } label: {
                    ZStack {
                        Text("add")
                            .opacity(store.isLoading ? 0 : 1)

                        if store.isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(!store.isValid || store.isLoading)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appSurface)
        .alert($store.scope(state: \.alert, action: \.alert))
        .task {
            isPriceFieldFocused = true
        }
    }

    private var priceBinding: Binding<String> {
        Binding(
            get: {
                formatPrice(store.price)
            },
            set: { newValue in
                let digits = onlyDigits(newValue)
                store.send(.binding(.set(\.price, digits)))
            }
        )
    }

    private var formattedPreviewPrice: String {
        guard let value = Int(store.price), value > 0 else {
            return "- \(store.currencyCode.rawValue)"
        }
        return "\(formatNumber(value)) \(store.currencyCode.rawValue)"
    }

    private func onlyDigits(_ string: String) -> String {
        string.filter(\.isNumber)
    }

    private func formatPrice(_ raw: String) -> String {
        guard let value = Int(raw), value > 0 else { return raw }
        return formatNumber(value)
    }

    private func formatNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

#Preview {
    NavigationStack {
        AddPriceView(
            store: Store(
                initialState: AddPriceFeature.State(externalBook: .sample),
                reducer: {
                    AddPriceFeature()
                }
            )
        )
    }
}
