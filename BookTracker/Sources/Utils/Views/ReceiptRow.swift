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
    
    private func formattedPrice(micros: Int64, currencyCode: String?) -> String {
        CurrencyCode.formattedPriceMicros(amountInMicros: micros, currencyCode: currencyCode)
    }

    var body: some View {
        HStack {
            VStack {
                Text("\(idx + 1).")
                    .foregroundStyle(Color.appSecondaryText).font(.caption)
                Spacer()
            }.padding(.top, 2)
            VStack(alignment: .leading, spacing: 7.5) {
                Text(item.title ?? "-").foregroundStyle(Color.appPrimaryText).fontWeight(.bold).font(.subheadline).lineLimit(2).truncationMode(.tail)
                HStack(spacing: 7) {
                    Text(item.author ?? "-").foregroundStyle(Color.appSecondaryText).font(.caption)
                    Circle().frame(width: 3).foregroundStyle(Color.appSecondaryText)
                    Text(item.publisher ?? "-").foregroundStyle(Color.appSecondaryText).font(.caption2)
                }
            }
            Spacer()
            if type == .purchase, let micros = item.micros, micros > 0 {
                Text(formattedPrice(micros: micros, currencyCode: item.currencyCode))
                    .foregroundStyle(Color.appPrimaryText)
                    .font(.subheadline)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(.vertical, 12)
    }
}

