//
//  CustomBookListView.swift
//  BookTracker
//
//  Created by Claude on 5/2/26.
//

import ComposableArchitecture
import SwiftUI

struct CustomBookListView: View {
    let store: StoreOf<CustomBookListFeature>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if store.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.books.isEmpty {
                ContentUnavailableView(
                    "no_custom_books",
                    systemImage: "books.vertical"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(store.books) { book in
                            ExternalBookRow(book: book) {
                                store.send(.bookTapped(book))
                            }
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    store.send(.deleteTapped(id: book.id))
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(Color.appSecondaryText)
                                }
                                .padding(8)
                            }
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.top, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .navigationTitle("my_custom_books")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Label("back", systemImage: "chevron.left")
                }
            }
            if !store.books.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        store.send(.clearAllTapped)
                    } label: {
                        Text("clear_all")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}
