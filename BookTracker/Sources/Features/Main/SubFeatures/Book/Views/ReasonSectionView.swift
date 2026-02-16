//
//  ReasonSectionView.swift
//  BookTracker
//
//  Created by 배성연 on 2/13/26.
//

import ComposableArchitecture
import SwiftUI

struct ReasonSectionView: View {
    @Bindable var store: StoreOf<BookFormFeature>

    var body: some View {
        VStack(alignment: .leading) {
            FormTextEditor(placeholder: "중단이유를 입력해주세요", text: $store.reason)
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}
