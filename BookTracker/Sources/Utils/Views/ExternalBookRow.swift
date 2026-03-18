//
//  ExternalBookRow.swift
//  BookTracker
//
//  Created by 배성연 on 2/17/26.
//

import SwiftUI

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
                    .foregroundStyle(.white)

                HStack(alignment: .top, spacing: 10) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "#2A2A33", default: .gray))
                        .frame(width: 100, height: 120)
                        .overlay {
                            if let url = book.thumbnail {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        Image(systemName: "photo")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.secondary)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 100, height: 120)
                                    case .failure:
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.secondary)
                                    @unknown default:
                                        Image(systemName: "photo")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            } else {
                                Image(systemName: "photo")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        if let author = book.authors?.first {
                            Text(author).foregroundStyle(.white.opacity(0.7)).font(.system(size: 14, weight: .semibold))
                                .lineLimit(2)
                                .truncationMode(.tail)
                        }

                        if let publisher = book.publisher {
                            Text(publisher).foregroundStyle(.white.opacity(0.6)).font(.system(size: 11, weight: .semibold))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }

                        if let micros = book.saleInfo?.offers?.first?.retailPrice?.amountInMicros {
                            let amount = Double(micros) / 1_000_000
                            Text("\(Int(amount))원").fontWeight(.semibold)
                        }
                    }
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(hex: "#17171C"))
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
