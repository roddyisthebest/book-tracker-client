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
    var isSheet: Bool = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Search Field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.appSecondaryText)
                TextField(
                    "search_placeholder",
                    text: $store.query
                )
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .foregroundStyle(Color.appPrimaryText)
                .submitLabel(.search)
                .overlay(alignment: .trailing) {
                    if !$store.query.wrappedValue.isEmpty {
                        Button {
                            store.send(.queryResetButtonTapped)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.appSecondaryText)
                                .padding(.horizontal, 6)
                        }
                    }
                }
            }
            .padding(12)
            .background(Color.appSurfaceDeep)
            .cornerRadius(12)
            .padding(.horizontal, 15)
            .padding(.top)
            .padding(.bottom, 5)

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
        .background(isSheet ? Color.appSurface : Color.appBackground)
        .sheet(
            item: $store.scope(state: \.detailSheet, action: \.detailSheet)
        ) { store in
            NavigationStack {
                ExternalBookDetailView(store: store)
            }
        }
        .navigationTitle("search")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isSheet {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Label("back", systemImage: "chevron.left")
                    }
                }
            }
        }
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
