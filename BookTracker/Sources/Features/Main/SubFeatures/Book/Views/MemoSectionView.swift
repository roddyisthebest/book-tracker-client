//
//  MemoSectionView.swift
//  BookTracker
//
//  Created by 배성연 on 2/13/26.
//

import ComposableArchitecture
import SwiftUI

struct MemoSectionView: View {
    @Bindable var store: StoreOf<BookFormFeature>

    var body: some View {
        VStack(alignment: .leading) {
            FormTextEditor(placeholder: "메모를 입력해주세요", text: $store.note)
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}
