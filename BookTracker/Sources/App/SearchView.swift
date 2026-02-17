//
//  SearchView.swift
//  BookTracker
//
//  Created by 배성연 on 2/17/26.
//

import ComposableArchitecture
import SwiftUI

struct SearchView: View {
    let store: StoreOf<SearchFeature>

    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack(spacing: 0) {
                // Search Field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField(
                        "검색어를 입력하세요",
                        text: viewStore.binding(get: \.query, send: { .queryChanged($0) })
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
                .padding(.top, 12)

                // Content
                SwitchStore(store.scope(state: \.destination, action: \.destination)) {
                    CaseLet(/SearchFeature.Destination.State.suggestions, action: SearchFeature.Destination.Action.suggestions) { suggestionsStore in
                        SearchSuggestionsView(store: suggestionsStore)
                    }
                    CaseLet(/SearchFeature.Destination.State.results, action: SearchFeature.Destination.Action.results) { resultsStore in
                        SearchResultView(store: resultsStore)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

#Preview {
    SearchView(
        store: Store(initialState: SearchFeature.State()) {
            SearchFeature()
        }
    )
}
