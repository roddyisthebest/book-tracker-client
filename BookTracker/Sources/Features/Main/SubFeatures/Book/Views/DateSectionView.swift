//
//  DateSectionView.swift
//  BookTracker
//
//  Created by 배성연 on 2/13/26.
//

import ComposableArchitecture
import SwiftUI

struct DateSectionView: View {
    @Bindable var store: StoreOf<BookFormFeature>

    var body: some View {
        VStack(alignment: .leading) {
            VStack {
                DatePicker("시작일자", selection: $store.startedAt, displayedComponents: [.date])
                    .padding()
            }
            .background(Color(hex: "#17171C", default: .accentColor))
            .cornerRadius(15)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}
