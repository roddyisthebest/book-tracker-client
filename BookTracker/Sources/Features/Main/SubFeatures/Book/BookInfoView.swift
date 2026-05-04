//
//  BookInfoView.swift
//  BookTracker
//
//  Created by 배성연 on 4/27/26.
//

import ComposableArchitecture
import Kingfisher
import SwiftUI

struct BookInfoView: View {
    var store: StoreOf<BookInfoFeature>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            if store.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
            } else if let message = store.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.yellow)
                    Text(message)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                    Button {
                        store.send(.retryButtonTapped)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text("retry")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else if let book = store.externalBook {
                ScrollView {
                    // MARK: - Header
                    HStack(alignment: .top, spacing: 15) {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .fill(Color.appSurfaceDeep)
                            .frame(width: 100, height: 150)
                            .overlay {
                                if let url = book.thumbnail {
                                    KFImage(url)
                                        .placeholder {
                                            ProgressView().tint(.secondary)
                                        }
                                        .retry(maxCount: 2, interval: .seconds(1))
                                        .fade(duration: 0.2)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 150)
                                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                                        .clipped()
                                } else {
                                    Image(systemName: "photo")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))

                        VStack(alignment: .leading, spacing: 10) {
                            Text(book.title)
                                .font(.system(size: 18, weight: .bold))
                                .lineLimit(2)
                                .truncationMode(.tail)
                                .foregroundStyle(Color.appPrimaryText)

                            VStack(alignment: .leading, spacing: 5) {
                                if let authors = book.authors, !authors.isEmpty {
                                    Text(authors.joined(separator: ", "))
                                        .foregroundStyle(Color.appSecondaryText)
                                        .font(.system(size: 15, weight: .semibold))
                                        .lineLimit(2)
                                        .truncationMode(.tail)
                                }

                                if let publisher = book.publisher {
                                    Text(publisher)
                                        .foregroundStyle(Color.appSecondaryText.opacity(0.8))
                                        .font(.system(size: 12, weight: .semibold))
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }

                                if let publishedDate = book.publishedDate {
                                    Text(publishedDate)
                                        .foregroundStyle(Color.appSecondaryText.opacity(0.8))
                                        .font(.system(size: 12, weight: .semibold))
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 10)

                    Divider().background(Color.appSeparator)

                    // MARK: - Detail Info
                    VStack(alignment: .leading, spacing: 16) {
                        if let categories = book.categories, !categories.isEmpty {
                            InfoRow(
                                label: String(localized: "category"),
                                value: categories.joined(separator: ", ")
                            )
                        }

                        if let pageCount = book.pageCount {
                            InfoRow(
                                label: String(localized: "page_count_info"),
                                value: pageCount.commaFormatted
                            )
                        }

                        if let isbn = book.isbn13 {
                            InfoRow(
                                label: String(localized: "isbn_label"),
                                value: isbn
                            )
                        }

                        if let isEbook = book.saleInfo?.isEbook {
                            InfoRow(
                                label: String(localized: "ebook_label"),
                                value: isEbook ? String(localized: "yes") : String(localized: "no")
                            )
                        }

                        if let language = book.language {
                            InfoRow(
                                label: String(localized: "language_label"),
                                value: language.uppercased()
                            )
                        }

                        if let retailPrice = book.saleInfo?.retailPrice,
                           let amount = retailPrice.amount,
                           let code = retailPrice.currencyCode {
                            InfoRow(
                                label: String(localized: "price_label"),
                                value: CurrencyCode.formattedPrice(amount: Int(amount), currencyCode: code)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                    // MARK: - Description
                    if let desc = book.description, !desc.isEmpty {
                        Rectangle().fill(Color.appSurfaceDeeper).frame(height: 15)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("book_intro")
                                    .foregroundStyle(Color.appPrimaryText)
                                    .font(.system(size: 22))
                                    .fontWeight(.black)
                                Spacer()
                            }
                            .padding(.vertical, 5)

                            Text(desc.strippingHTML)
                                .font(.system(size: 15))
                                .foregroundStyle(Color.appSecondaryText)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }

                    // MARK: - Google Play Link
                    if let infoLink = book.infoLink {
                        Rectangle().fill(Color.appSurfaceDeeper).frame(height: 15)

                        VStack {
                            Link(destination: infoLink) {
                                HStack(spacing: 8) {
                                    Image(systemName: "link")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("view_on_google_play")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.appButtonSurface)
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appSurface)
        .navigationTitle("book_info")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
        }
        .task {
            store.send(.onAppear)
        }
    }
}

// MARK: - InfoRow

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundStyle(Color.appSecondaryText)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 80, alignment: .leading)
            Spacer(minLength: 12)
            Text(value)
                .foregroundStyle(Color.appPrimaryText)
                .font(.system(size: 15, weight: .bold))
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

#Preview {
    NavigationStack {
        BookInfoView(store: Store(initialState: BookInfoFeature.State(externalBookId: ExternalBook.sample.id), reducer: {
            BookInfoFeature()
        }))
    }
}
