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
                Text("recent_searches")
                    .font(.headline)
                    .foregroundStyle(Color.appPrimaryText)
                    .padding(.horizontal, 15)

                Group {
                    if store.isSearchesLoading {
                        ProgressView()
                            .tint(Color.appBorder)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    } else {
                        switch store.searchesResult {
                        case .success(let items) where !items.isEmpty:
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 10) {
                                    ForEach(items, id: \.id) { search in
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
                        case .success:
                            Text("no_recent_searches")
                                .font(.subheadline)
                                .foregroundStyle(Color.appSecondaryText)
                        case .failure:
                            VStack(spacing: 8) {
                                Text("load_failed")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.appSecondaryText)
                                Button(action: { store.send(.loadRecents) }) {
                                    Text("retry")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color.appPrimaryText)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 15)
                .padding(.bottom)

                // Recommended Searches Section
                Text("recommended_searches")
                    .font(.headline)
                    .foregroundStyle(Color.appPrimaryText)
                    .padding(.horizontal, 15)

                Group {
                    if store.isSearchKeywordsLoading {
                        ProgressView()
                            .tint(Color.appBorder)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    } else {
                        switch store.searchKeywordsResult {
                        case .success(let keywords) where !keywords.isEmpty:
                            FlowLayout(spacing: 10, rowSpacing: 10) {
                                ForEach(keywords) { keyword in
                                    RecommendedSearchBadge(id: keyword.id.uuidString, keyword: keyword.keyword) {
                                        store.send(.searchTapped(text: keyword.keyword))
                                    }
                                }
                            }
                        case .success:
                            Text("no_recommended_searches")
                                .font(.subheadline)
                                .foregroundStyle(Color.appSecondaryText)
                        case .failure:
                            VStack(spacing: 8) {
                                Text("load_failed")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.appSecondaryText)
                                Button(action: { store.send(.loadSearchKeyword) }) {
                                    Text("retry")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color.appPrimaryText)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 15)
                .padding(.bottom)

                // My Custom Books Section
                Text("my_custom_books")
                    .font(.headline)
                    .foregroundStyle(Color.appPrimaryText)
                    .padding(.horizontal, 15)

                VStack(spacing: 14) {
                    Button {
                        store.send(.addCustomBookTapped)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                            Text("add_custom_book")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(Color.appPrimaryText)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.appSurfaceDeep)
                        .cornerRadius(20)
                    }

                    Button {
                        store.send(.openCustomBookListTapped)
                    } label: {
                        HStack(spacing: 6) {
                            Text("view_custom_books")
                                .font(.system(size: 13, weight: .medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(Color.appSecondaryText)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
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
