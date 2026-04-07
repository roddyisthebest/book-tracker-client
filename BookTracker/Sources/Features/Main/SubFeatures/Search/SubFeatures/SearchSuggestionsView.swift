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
                Text("최근 검색어")
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
                            Text("최근 검색어가 없어요")
                                .font(.subheadline)
                                .foregroundStyle(Color.appSecondaryText)
                        case .failure:
                            VStack(spacing: 8) {
                                Text("불러오지 못했어요")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.appSecondaryText)
                                Button(action: { store.send(.loadRecents) }) {
                                    Text("다시 시도")
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
                Text("추천 검색어")
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
                            Text("추천 검색어가 없어요")
                                .font(.subheadline)
                                .foregroundStyle(Color.appSecondaryText)
                        case .failure:
                            VStack(spacing: 8) {
                                Text("불러오지 못했어요")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.appSecondaryText)
                                Button(action: { store.send(.loadSearchKeyword) }) {
                                    Text("다시 시도")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color.appPrimaryText)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 15)
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
