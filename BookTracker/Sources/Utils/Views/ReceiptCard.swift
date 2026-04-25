//
//  ReceiptCard.swift
//  BookTracker
//
//  Created by 배성연 on 2/5/26.
//

import SwiftUI

struct ReceiptCard: View {
    let receipt: ReceiptSummary
    let onTapped: (() -> Void)?
    let onDelete: (() -> Void)?

    private var localeCurrency: CurrencyCode {
        let lang = Locale.current.language.languageCode?.identifier ?? ""
        switch lang {
        case "ko": return .krw
        case "ja": return .jpy
        default:   return .usd
        }
    }

    private static let receiptDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        let isRental = receipt.type == .rental

        Button(action: {
            if let onTapped {
                onTapped()
            }
        }) {
            VStack(spacing: 10) {
                HStack {
                    if isRental {
                        HStack {
                            Image(systemName: "person.text.rectangle.fill")
                                .font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.appRentalAccent)
                            Text("rental_receipt").foregroundStyle(Color.appRentalAccent).font(.system(size: 14, weight: .bold))

                        }.padding(10).background(Color.appRentalBadgeFill).cornerRadius(15)
                    }
                    else {
                        HStack {
                            Image(systemName: "receipt.fill")
                                .font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.appPurchaseAccent)
                            Text("purchase_receipt").foregroundStyle(Color.appPurchaseAccent).font(.system(size: 14, weight: .bold))
                        }.padding(10).background(Color.appPurchaseBadgeFill).cornerRadius(15)
                    }
                    Spacer()
                }

                HStack(spacing: 2.5) {
                    let firstBookTitle = receipt.firstBookTitle ?? (receipt.type == .rental ? String(localized: "rental_receipt") : String(localized: "purchase_receipt"))
                    Text(firstBookTitle)
                        .foregroundStyle(Color.appPrimaryText)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    let restQuantity = max(receipt.totalQuantity - 1, 0)
                    if restQuantity > 0 {
                        Text(String(format: String(localized: "and_more_count %@"), "\(restQuantity)"))
                            .foregroundStyle(Color.appPrimaryText)
                            .fontWeight(.bold).layoutPriority(1)
                    }

                    Spacer()
                }.padding(.vertical, 7).padding(.leading, 5)

                HStack(spacing: 5) {
                    if isRental {
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 14)).foregroundStyle(Color.appRentalAccent)

                        Text(receipt.source).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.appPrimaryText).lineLimit(1).truncationMode(.tail)
                    }
                    else {
                        let localeCurrency = localeCurrency
                        Image(systemName: localeCurrency.symbolName)
                            .font(.system(size: 14)).foregroundStyle(Color.appPurchaseAccent)

                        if let totalUsdMicros = receipt.totalUsdMicros, totalUsdMicros > 0 {
                            let converted = CurrencyCode.convertMicros(totalUsdMicros, from: .usd, to: localeCurrency)
                            Text(CurrencyCode.formattedPriceMicros(amountInMicros: converted, currencyCode: localeCurrency.rawValue)).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.appPrimaryText).lineLimit(1).truncationMode(.tail)
                        } else if let totalMicros = receipt.totalMicros, totalMicros > 0 {
                            let source = receipt.sourceCurrencyCode
                            Text(CurrencyCode.formattedPriceMicros(amountInMicros: totalMicros, currencyCode: source.rawValue)).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.appPrimaryText).lineLimit(1).truncationMode(.tail)
                        }
                    }

                    Spacer()
                }.padding(.leading, 3)

                HStack {
                    if let date = receipt.receiptAt {
                        Text(Self.receiptDateFormatter.string(from: date))
                            .foregroundStyle(Color.appSecondaryText)
                            .font(.system(size: 14))
                    }
                    Spacer()
                }.padding(.leading, 5)

            }.frame(maxWidth: .infinity, maxHeight: .infinity).padding(.horizontal, 10).padding(.vertical, 15).background(Color.appSurface).cornerRadius(10)
        }

        .contextMenu {
            Button(role: .destructive) {
                onDelete?()
            } label: {
                Label("delete", systemImage: "trash")
            }
        }
    }
}

#Preview("Rental") {
    let sample = ReceiptSummary(
        id: UUID(),
        createdAt: Date(),
        receiptAt: Date(),
        source: "서울시립도서관",
        totalMicros: nil,
        totalUsdMicros: nil,
        type: .rental,
        firstBookTitle: "모비딕",
        totalQuantity: 3,
        sourceCurrencyCode: .krw
    )
    return ReceiptCard(
        receipt: sample,
        onTapped: {},
        onDelete: {}
    )
    .padding()
    .frame(width: 170)
    .background(Color(hex: "#101013", default: .black))
    .preferredColorScheme(.dark)
}

#Preview("Purchase") {
    let sample = ReceiptSummary(
        id: UUID(),
        createdAt: Date(),
        receiptAt: Date(),
        source: "교보문고",
        totalMicros: 24_500_000_000,
        totalUsdMicros: 18_148_000,
        type: .purchase,
        firstBookTitle: "스위프트 TCA",
        totalQuantity: 1,
        sourceCurrencyCode: .krw
    )
    return ReceiptCard(
        receipt: sample,
        onTapped: {},
        onDelete: {}
    )
    .padding()
    .frame(width: 170)
    .background(Color(hex: "#101013", default: .black))
    .preferredColorScheme(.dark)
}
