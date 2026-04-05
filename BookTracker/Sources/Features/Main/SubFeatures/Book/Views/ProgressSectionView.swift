//
//  ProgressSectionView.swift
//  BookTracker
//
//  Created by 배성연 on 2/13/26.
//

import ComposableArchitecture
import SwiftUI

struct ProgressSectionView: View {
    @Bindable var store: StoreOf<BookFormFeature>

    var body: some View {
        VStack(alignment: .leading) {
            VStack {
                Slider(value: $store.progress, in: 0 ... 100, step: 1).padding()

                Divider().background(Color.appSeparator)
                HStack {
                    Text("\(store.progress, specifier: "%.0f")%").fontWeight(.semibold)
                    Spacer()

                    HStack {
                        HStack(spacing: 5) {
                            TextField("0", text: $store.page)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 10)
                                .background(Color.appPlaceholder)
                                .cornerRadius(5)
                                .keyboardType(.numberPad)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .foregroundStyle(Color.appPrimaryText)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 60)
                            Text("p")
                        }
                        Text("/").foregroundStyle(Color.appSecondaryText)
                        if store.pageCountEditable {
                            TextField("0", text: $store.entirePage)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 10)
                                .background(Color.appPlaceholder)
                                .cornerRadius(5)
                                .keyboardType(.numberPad)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .foregroundStyle(Color.appPrimaryText)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 60)
                        }
                        else {
                            Text("\(store.entirePage)p")
                        }
                    }

                }.padding(.horizontal).padding(.bottom, 15).padding(.top, 5)
            }
            .background(Color.appSurfaceDeep)
            .cornerRadius(15)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

#Preview {
    ProgressSectionView(store: Store(initialState: BookFormFeature.State(externalId: "2", bookId: UUID(2)), reducer: {
        BookFormFeature()
    }))
}
