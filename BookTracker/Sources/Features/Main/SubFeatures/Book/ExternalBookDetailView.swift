//
//  ExternalBookDetailView.swift
//  BookTracker
//
//  Created by 배성연 on 2/16/26.
//

import ComposableArchitecture
import Kingfisher
import SwiftUI

struct ExternalBookDetailView: View {
    var store: StoreOf<ExternalBookDetailFeature>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            if let message = store.errorMessage {
                VStack {
                    Text(message)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.red)
                        .font(.system(size: 15, weight: .semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else if store.isLoading && store.book == nil {
                ProgressView()
                    .scaleEffect(1.1)
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            } else {
                ScrollView {
                    HStack(alignment: .top, spacing: 15) {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.appSurfaceDeep)
                            .frame(width: 100, height: 150)
                            .overlay(
                                Group {
                                    if let url = store.book?.thumbnail {
                                        KFImage(url)
                                            .placeholder {
                                                ProgressView()
                                                    .tint(.secondary)
                                            }
                                            .retry(maxCount: 2, interval: .seconds(1))
                                            .fade(duration: 0.2)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 150)
                                            .clipShape(RoundedRectangle(cornerRadius: 15))
                                            .clipped()
                                    } else {
                                        Image(systemName: "photo")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            )

                        VStack(alignment: .leading, spacing: 10) {
                            if let book = store.book {
                                Text(book.title)
                                    .font(.system(size: 18, weight: .bold))
                                    .lineLimit(2)
                                    .truncationMode(.tail)
                                    .foregroundStyle(Color.appPrimaryText)

                                VStack(alignment: .leading, spacing: 5) {
                                    if let author = book.authors?.first {
                                        Text(author).foregroundStyle(Color.appSecondaryText).font(.system(size: 15, weight: .semibold))
                                            .lineLimit(2)
                                            .truncationMode(.tail)
                                    }

                                    if let publisher = book.publisher {
                                        Text(publisher).foregroundStyle(Color.appSecondaryText).font(.system(size: 12, weight: .semibold))
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                    }

                                    if let publishedDate = book.publishedDate {
                                        Text("published_date \(publishedDate)").foregroundStyle(Color.appSecondaryText).font(.system(size: 12, weight: .semibold))
                                            .lineLimit(1)
                                            .truncationMode(.tail).padding(.vertical, 5)
                                    }

                                    if let micros = book.saleInfo?.offers?.first?.retailPrice?.amountInMicros {
                                        let code = book.saleInfo?.offers?.first?.retailPrice?.currencyCode

                                        Text(CurrencyCode.formattedPriceMicros(amountInMicros: micros, currencyCode: code))
                                            .foregroundStyle(.blue).font(.system(size: 20, weight: .bold))
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                    }
                                }
                            }

                            Spacer()
                        }
                        Spacer()

                    }.padding(.horizontal, 15).padding(.vertical, 10)

                    Divider().background(Color.appSeparator)

                    VStack {
                        if let book = store.book {
                            if let desc = book.description {
                                HStack {
                                    Text("book_intro").foregroundStyle(Color.appPrimaryText).font(.system(size: 22)).fontWeight(.black)
                                    Spacer()
                                }
                                .padding(.vertical, 5)

                                Text(desc.strippingHTML)
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color.appSecondaryText)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(store.isExtended ? 15 : 3)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                HStack {
                                    Button(action: {
                                        store.send(.extendButtonTapped)
                                    }) {
                                        Text(store.isExtended ? String(localized: "collapse") : String(localized: "show_more"))
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 5)
                            } else if book.isCustom {
                                HStack {
                                    Text("custom_book_placeholder")
                                        .font(.system(size: 15))
                                        .foregroundStyle(Color.appSecondaryText)
                                    Spacer()
                                }
                                .padding(.vertical, 5)
                            }
                        }

                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                if store.receiptTypesLoadState == .loading {
                                    HStack(spacing: 10) {
                                        ProgressView()
                                            .controlSize(.small)

                                        Text("loading_receipt_info")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Color.appSecondaryText)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 56)
                                    .padding(.horizontal, 16)
                                    .background(Color.appButtonSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else if store.receiptTypesLoadState == .error {
                                    VStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(.orange)

                                        Text("receipt_info_load_failed")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(Color.appPrimaryText)

                                        Text("try_again_later")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(Color.appSecondaryText)
                                    }
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity, minHeight: 88)
                                    .padding(.horizontal, 16)
                                    .background(Color.appButtonSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else if store.receiptTypesLoadState == .loaded {
                                    Button(action: {
                                        store.send(.addButtonTapped(.rental))
                                    }) {
                                        HStack(spacing: 8) {
                                            if store.isRentalSaving {
                                                ProgressView()
                                                    .controlSize(.small)
                                            } else {
                                                Image(systemName: "person.text.rectangle.fill")
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundStyle(
                                                        Color.appRentalAccent)

                                                Text("add_to_rental")
                                                    .foregroundStyle(Color.appSecondaryText)
                                                    .fontWeight(.semibold)
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.appButtonSurface)
                                        .cornerRadius(10)
                                    }.disabled(store.isRentalSaving)

                                    Button(action: {
                                        store.send(.addButtonTapped(.purchase))
                                    }) {
                                        HStack(spacing: 8) {
                                            if store.isPurchasingSaving {
                                                ProgressView()
                                                    .controlSize(.small)
                                            } else {
                                                Image(systemName: "receipt.fill")
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundStyle(Color.appPurchaseAccent)
                                                Text("add_to_receipt")
                                                    .foregroundStyle(Color.appSecondaryText)
                                                    .fontWeight(.semibold)
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.appButtonSurface)
                                        .cornerRadius(10)
                                    }.disabled(store.isPurchasingSaving)
                                }
                            }
                            Button(action: {
                                store.send(.addButtonTapped(.mybooks(externalId: store.id)))
                            }) {
                                HStack(spacing: 8) {
                                    let exists = store.isAlreadyRegistered
                                    Image(systemName: "books.vertical.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(
                                            exists == nil ? .gray : (exists == true ? .gray : .blue)
                                        )
                                    Text({
                                        if store.isAlreadyRegistered == nil {
                                            return String(localized: "checking_registration")
                                        } else if store.isAlreadyRegistered == true {
                                            return String(localized: "already_registered")
                                        } else {
                                            return String(localized: "add_to_bookshelf")
                                        }
                                    }())
                                        .foregroundStyle(Color.appSecondaryText)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.appButtonSurface)
                                .cornerRadius(10)
                            }
                            .disabled(store.isAlreadyRegistered == nil || store.isAlreadyRegistered == true)
                            .overlay(alignment: .trailing) {
                                if store.isAlreadyRegistered == nil {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.secondary)
                                        .padding(.trailing, 12)
                                }
                            }
                            .animation(.easeInOut, value: store.isAlreadyRegistered)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }

                if store.isLoading {
                    ProgressView()
                        .scaleEffect(1.1)
                        .padding(16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appSurface)
        .navigationTitle("book_detail")
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
        .sheet(store: store.scope(state: \.$destination.formBook, action: \.destination.formBook)) {
            formBookStore in
            NavigationStack {
                BookFormView(store: formBookStore)
            }
        }
        .sheet(store: store.scope(state: \.$destination.addPrice, action: \.destination.addPrice)) {
            addPriceFeature in
            NavigationStack {
                AddPriceView(store: addPriceFeature)
            }
        }
        .alert(store: store.scope(state: \.$destination.alert, action: \.destination.alert))
        .task {
            await store.send(.onAppear).finish()
        }
    }
}

#Preview {
    NavigationStack {
        ExternalBookDetailView(store: Store(initialState: ExternalBookDetailFeature.State(id: ExternalBook.sample.id), reducer: {
            ExternalBookDetailFeature()
        }))
    }
}
