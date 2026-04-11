//
//  ExternalBookRow.swift
//  BookTracker
//
//  Created by 배성연 on 2/17/26.
//

import SwiftUI
import Kingfisher

struct ExternalBookRow: View {
    let book: ExternalBook
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading) {
                Text(book.title)
                    .font(.system(size: 18, weight: .bold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(Color.appPrimaryText)

                HStack(alignment: .top, spacing: 10) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.appSurface)
                        .frame(width: 100, height: 120)
                        .overlay {
                            if let url = book.thumbnail {
                                KFImage(url)
                                    .placeholder {
                                        ProgressView().tint(.secondary)
                                    }
                                    .onFailure { _ in }
                                    .retry(maxCount: 2, interval: .seconds(1))
                                    .fade(duration: 0.2)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            } else {
                                Image(systemName: "photo")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        if let author = book.authors?.first {
                            Text(author).foregroundStyle(Color.appSecondaryText).font(.system(size: 14, weight: .semibold))
                                .lineLimit(2)
                                .truncationMode(.tail)
                        }

                        if let publisher = book.publisher {
                            Text(publisher).foregroundStyle(Color.appSecondaryText.opacity(0.8)).font(.system(size: 11, weight: .semibold))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }

                        if let micros = book.saleInfo?.offers?.first?.retailPrice?.amountInMicros {
                            let amount = Double(micros) / 1_000_000
                            Text("price_won \(Int(amount))").fontWeight(.semibold)
                        }
                    }
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.appSurfaceDeep)
        .cornerRadius(10)
    }
}

#Preview("SelectBookRow Samples") {
    VStack(spacing: 16) {
        ExternalBookRow(
            book: ExternalBook.sample,
            onTap: {},
        )
    }
    .padding()
    .background(.black)
}
