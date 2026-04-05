//
//  ReceiptRow.swift
//  BookTracker
//
//  Created by 배성연 on 2/4/26.
//

import Foundation
import SwiftUI

struct ReceiptRow: View {
    let idx: Int
    let type: ReceiptType
    let item: ReceiptDetailItem
    
    private func formattedPrice(price: Int, currencyCode: String?) -> String {
        let code = (currencyCode?.uppercased()) ?? "KRW"
        if code == "KRW" || code == "WON" {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.groupingSeparator = ","
            formatter.maximumFractionDigits = 0
            let value = formatter.string(from: NSNumber(value: price)) ?? "\(price)"
            return "\(value)원"
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = code
            let value = formatter.string(from: NSNumber(value: price)) ?? "\(price) \(code)"
            return value
        }
    }
    
    var body: some View {
        HStack {
            VStack {
                Text("\(idx + 1).")
                    .foregroundStyle(.white.opacity(0.5)).font(.caption)
                Spacer()
            }.padding(.top, 2)
            VStack(alignment: .leading, spacing: 7.5) {
                Text(item.title ?? "-").foregroundStyle(.white).fontWeight(.bold).font(.subheadline).lineLimit(2).truncationMode(.tail)
                HStack(spacing: 7) {
                    Text(item.author ?? "-").foregroundStyle(.white.opacity(0.75)).font(.caption)
                    Circle().frame(width: 3).foregroundStyle(.white.opacity(0.75))
                    Text(item.publisher ?? "-").foregroundStyle(.white.opacity(0.75)).font(.caption2)
                }
            }
            Spacer()
            if type == .purchase, let price = item.price, price > 0 {
                Text(formattedPrice(price: price, currencyCode: item.currencyCode))
                    .foregroundStyle(.white)
                    .font(.subheadline)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(.vertical, 12)
    }
}

