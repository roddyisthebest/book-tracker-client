//
//  SearchSuggestionsView.swift
//  BookTracker
//
//  Created by 배성연 on 2/17/26.
//

import ComposableArchitecture
import SwiftUI

struct SearchSuggestionsView: View {
    let store: StoreOf<SearchSuggestionsFeature>
    let columns = [
        GridItem(.adaptive(minimum: 42), alignment: .leading)
    ]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Recent Searches Section
                if !store.searches.isEmpty {
                    Text("최근 검색어")
                        .font(.headline)
                        .padding(.horizontal, 15)
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 10) {
                            ForEach(store.searches, id: \.id) { search in
                                SearchBadge(
                                    id: search.id,
                                    text: search.text,
                                    onTapped: {
                                        store.send(.searchTapped(text: search.text))
                                    },
                                    onDeleted: {
                                        store.send(.deleteButtonTapped(id: search.id))
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.bottom)
                }

                // Recommended Searches Section
                if !store.books.isEmpty {
                    Text("추천 검색어")
                        .font(.headline)
                        .padding(.horizontal, 15)
                    FlowLayout(spacing: 10, rowSpacing: 10) {
                        ForEach(store.books, id: \.id) { book in
                            RecommendedSearchBadge(id: book.id, book: book) {
                                store.send(.searchTapped(text: book.title))
                            }
                        }
                    }
                    .padding(.horizontal, 15)
                }
            }
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { store.send(.onAppear) }
    }
}

#Preview {
    SearchSuggestionsView(store: Store(initialState: SearchSuggestionsFeature.State(), reducer: {
        SearchSuggestionsFeature()
    }))
}
