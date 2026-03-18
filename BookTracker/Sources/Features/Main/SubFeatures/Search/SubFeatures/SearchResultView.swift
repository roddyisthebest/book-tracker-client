//
//  SearchResultView.swift
//  BookTracker
//
//  Created by 배성연 on 2/16/26.
//

import ComposableArchitecture
import SwiftUI

struct SearchResultView: View {
    let store: StoreOf<SearchResultFeature>
    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack {
                    ForEach(store.externalBooks, id: \.id) { book in
                        ExternalBookRow(
                            book: book,
                            onTap: {
                                store.send(.externalBookTapped(id: book.id))
                            }
                        )
                        .onAppear {
                            if book.id == store.externalBooks.last?.id {
                                store.send(.loadMore)
                            }
                        }
                    }
                    if store.isLoadingMore {
                        ProgressView()
                            .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, 15)
                .padding(.top, 10)
            }
            .allowsHitTesting(!(store.isLoading && store.externalBooks.isEmpty))

            if store.isLoading && store.externalBooks.isEmpty {
                ProgressView()
                    .scaleEffect(1.1)
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert(store: store.scope(state: \.$alert, action: \.alert))
        .refreshable {
            await store.send(.refresh).finish()
        }
    }
}

#Preview {
    SearchResultView(store: Store(initialState: SearchResultFeature.State(), reducer: {
        SearchResultFeature()
    }))
}
