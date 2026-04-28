import Kingfisher
import SwiftUI

struct DeleteReceiptBookRow: View {
    let book: ReceiptBook
    let onTap: () -> Void
    let onDelete: () -> Void

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
                                        Image(systemName: "photo")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.secondary)
                                    }
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
                        if let author = book.authors.first, !author.isEmpty {
                            Text(author)
                                .foregroundStyle(Color.appSecondaryText)
                                .font(.system(size: 14, weight: .semibold))
                                .lineLimit(2)
                                .truncationMode(.tail)
                        }

                        if let publisher = book.publisher, !publisher.isEmpty {
                            Text(publisher)
                                .foregroundStyle(Color.appSecondaryText)
                                .font(.system(size: 11, weight: .semibold))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }

                        if let isbn = book.isbn13, !isbn.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "barcode")
                                    .font(.system(size: 12, weight: .semibold))

                                Text("ISBN \(isbn)")
                                    .font(.caption2)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .foregroundStyle(Color.appPrimaryText)
                            }
                            .padding(6)
                            .background(Color.appSurface)
                            .cornerRadius(4)
                            .padding(.top, 2)
                        }

                        if let micros = book.saleInfo?.amountInMicros {
                            Text(CurrencyCode.formattedPriceMicros(amountInMicros: micros, currencyCode: book.saleInfo?.currencyCode?.rawValue))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.appPrimaryText)
                                .padding(.top, 2)
                        }
                    }

                    Spacer()
                }
            }
            .padding()
            .background(Color.appSurfaceDeep)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .overlay(alignment: .topTrailing) {
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.red)
                    .padding(12)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview("DeleteExternalBookRow Samples") {
    VStack(spacing: 16) {
        DeleteReceiptBookRow(
            book: .sample(),
            onTap: {},
            onDelete: {}
        )
    }
    .padding()
    .background(.black)
}
