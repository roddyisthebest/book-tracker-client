//
//  SearchView.swift
//  BookTracker
//
//  Created by 배성연 on 2/17/26.
//

import ComposableArchitecture
import SwiftUI

struct SearchView: View {
    @Bindable var store: StoreOf<SearchFeature>

    var body: some View {
        VStack(spacing: 0) {
            // Search Field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(
                    "검색어를 입력하세요",
                    text: $store.query
                )
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .foregroundStyle(.primary)
                .submitLabel(.search)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 15)
            .padding(.top)
            .padding(.bottom, 20)

            switch store.state.destination {
            case .suggestions:
                if let suggestionsStore = store.scope(state: \.destination.suggestions, action: \.destination.suggestions) {
                    SearchSuggestionsView(store: suggestionsStore)
                }
            case .results:
                if let resultsStore = store.scope(state: \.destination.results, action: \.destination.results) {
                    SearchResultView(store: resultsStore)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(
            item: $store.scope(state: \.detailSheet, action: \.detailSheet)
        ) { store in
            NavigationStack {
                ExternalBookDetailView(store: store)
            }
        }
        .navigationTitle("검색")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SearchView(
            store: Store(initialState: SearchFeature.State()) {
                SearchFeature()
            }
        )
    }
}
