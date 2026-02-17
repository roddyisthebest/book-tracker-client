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
        ScrollView {
            LazyVStack {
                ForEach(store.externalBooks, id: \.id) { book in
                    ExternalBookRow(
                        book: book,
                        onTap: {
                            store.send(.externalBookTapped(id: book.id))
                        }
                    )
                }
            }
            .padding(.horizontal, 15).padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SearchResultView(store: Store(initialState: SearchResultFeature.State(), reducer: {
        SearchResultFeature()
    }))
}
