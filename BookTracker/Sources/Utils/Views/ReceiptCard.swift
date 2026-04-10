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
                        Image(systemName: "wonsign")
                            .font(.system(size: 14)).foregroundStyle(Color.appPurchaseAccent)

                        if let totalPrice = receipt.totalPrice, totalPrice > 0 {
                            Text("price_won \(totalPrice)").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.appPrimaryText).lineLimit(1).truncationMode(.tail)
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

            // 필요하면 다른 메뉴도 추가 가능 (예: 공유)
            Button {
                // 공유 등 다른 액션
            } label: {
                Label("share", systemImage: "square.and.arrow.up")
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
        totalPrice: nil,
        type: .rental,
        firstBookTitle: "모비딕",
        totalQuantity: 3
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
        totalPrice: 245000000000000,
        type: .purchase,
        firstBookTitle: "스위프트 TCA",
        totalQuantity: 1
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
