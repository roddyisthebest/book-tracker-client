//
//  CollectionFormView.swift
//  BookTracker
//
//  Created by 배성연 on 2/7/26.
//
import ComposableArchitecture
import SwiftUI

struct CollectionFormView: View {
    @Bindable var store: StoreOf<CollectionFormFeature>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                VStack {
                    HStack {
                        FormLabel(text: String(localized: "collection_name_label"))
                        Spacer()
                    }
                    TextField(String(localized: "collection_name_label"),
                              text: $store.title,
                              prompt: Text("enter_collection_name").foregroundStyle(Color.appSecondaryText))
                        .foregroundStyle(Color.appPrimaryText)
                        .padding()
                        .background(Color.appSurfaceDeep)
                        .cornerRadius(15)
                }

                VStack {
                    HStack {
                        FormLabel(text: String(localized: "collection_desc_label"))
                        Spacer()
                    }

                    ZStack(alignment: .topLeading) {
                        if store.description.isEmpty {
                            Text("enter_collection_desc")
                                .foregroundStyle(Color.appSecondaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                        }

                        TextEditor(text: $store.description)
                            .foregroundStyle(Color.appPrimaryText)
                            .padding(12)
                            .frame(height: 150)
                            .scrollIndicators(.visible)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .textInputAutocapitalization(.sentences)
                            .autocorrectionDisabled(false)
                    }
                    .background(Color.appSurfaceDeep)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                }

                if !store.isEditing {
                    VStack(alignment: .leading) {
                        FormLabel(text: String(localized: "initial_book_select"))

                        Button(action: {
                            store.send(.presentBookPickerButtonTapped)
                        }) {
                            HStack {
                                Text("select_books")
                                Spacer()

                                HStack(spacing: 10) {
                                    let selectedBookIds = store.selectedBookIds
                                    if !selectedBookIds.isEmpty {
                                        Text("books_selected \(selectedBookIds.count)").foregroundStyle(.foreground)
                                    }

                                    Image(systemName: "chevron.right").fontWeight(.semibold).foregroundStyle(.foreground)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .background(Color.appSurfaceDeep)
                        .clipShape(RoundedRectangle(cornerRadius: 15))

                    }.frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.appSurface)
            .navigationTitle(store.isEditing ? "collection_edit" : "collection_create")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label("back", systemImage: "chevron.left")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if store.isLoading {
                        ProgressView()
                    } else if store.isEditing {
                        Button(String(localized: "update")) {
                            store.send(.updateButtonTapped)
                        }
                        .disabled(!store.isSubmitEnabled || store.isLoading)

                    } else {
                        Button(String(localized: "create")) {
                            store.send(.createButtonTapped)
                        }
                        .disabled(!store.isSubmitEnabled || store.isLoading)
                    }
                }
            }
            .sheet(item: $store.scope(state: \.addBooks, action: \.addBooks)) { addBooksStore in
                NavigationStack {
                    AddBooksView(store: addBooksStore)
                }
            }
            .alert($store.scope(state: \.alert, action: \.alert))
        }
    }
}

#Preview {
    CollectionFormView(
        store: Store(
            initialState: CollectionFormFeature.State(collection: UserCollection(id: UUID(), userId: UUID(), name: "My Collection", isDefault: false, createdAt: Date(), description: "")),
            reducer: { CollectionFormFeature() }
        )
    )
}
