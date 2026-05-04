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
            searchField
            destinationContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isSheet ? Color.appSurface : Color.appBackground)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
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
        .sheet(item: $store.scope(state: \.customBookForm, action: \.customBookForm)) { customBookStore in
            CustomBookFormView(store: customBookStore)
        }
        .sheet(item: $store.scope(state: \.customBookList, action: \.customBookList)) { listStore in
            NavigationStack {
                CustomBookListView(store: listStore)
            }
        }
    }

    @ViewBuilder
    private var searchField: some View {
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
    }

    @ViewBuilder
    private var destinationContent: some View {
        if let suggestionsStore = store.scope(state: \.destination?.suggestions, action: \.destination.suggestions) {
            SearchSuggestionsView(store: suggestionsStore)
        } else if let resultsStore = store.scope(state: \.destination?.results, action: \.destination.results) {
            SearchResultView(store: resultsStore)
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
