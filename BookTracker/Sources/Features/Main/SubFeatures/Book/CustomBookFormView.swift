//
//  CustomBookFormView.swift
//  BookTracker
//
//  Created by Claude on 5/2/26.
//

import ComposableArchitecture
import PhotosUI
import SwiftUI

struct CustomBookFormView: View {
    @Bindable var store: StoreOf<CustomBookFormFeature>
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem? = nil

    var body: some View {
        NavigationStack {
            List {
                // Cover Image
                FormCard(labelText: String(localized: "cover_image")) {
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        ZStack {
                            if let data = store.selectedImageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 140)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(alignment: .bottomTrailing) {
                                        Image(systemName: "pencil.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundStyle(Color.appPrimaryText)
                                            .background(Circle().fill(Color.appSurfaceDeep))
                                            .offset(x: 6, y: 6)
                                    }
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.appSecondaryText.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                                    .frame(width: 100, height: 140)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.appSurfaceDeep)
                                    )
                                    .overlay {
                                        VStack(spacing: 8) {
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 22))
                                                .foregroundStyle(Color.appSecondaryText)
                                            Text("select_image")
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundStyle(Color.appSecondaryText)
                                        }
                                    }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                    }
                }

                // Title (required)
                FormCard(labelText: String(localized: "book_title_label")) {
                    CustomFormTextField(
                        text: $store.title,
                        placeholder: "book_title_required"
                    )
                }

                // Author
                FormCard(labelText: String(localized: "author_label")) {
                    CustomFormTextField(
                        text: $store.author,
                        placeholder: "author_label"
                    )
                }

                // Publisher
                FormCard(labelText: String(localized: "publisher_label")) {
                    CustomFormTextField(
                        text: $store.publisher,
                        placeholder: "publisher_label"
                    )
                }

                // Page Count
                FormCard(labelText: String(localized: "page_count_label")) {
                    CustomFormTextField(
                        text: $store.pageCount,
                        placeholder: "page_count_label",
                        keyboardType: .numberPad
                    )
                }

                // ISBN
                FormCard(labelText: "ISBN") {
                    CustomFormTextField(
                        text: $store.isbn,
                        placeholder: "ISBN"
                    )
                }

                // Description
                FormCard(labelText: String(localized: "book_intro")) {
                    FormTextEditor(
                        placeholder: "book_intro",
                        text: $store.description,
                        height: 120
                    )
                }

                // Price
                FormCard(labelText: String(localized: "price")) {
                    VStack(spacing: 0) {
                        HStack(spacing: 10) {
                            TextField(
                                "",
                                text: $store.retailPrice,
                                prompt: Text("enter_price").foregroundStyle(Color.appSecondaryText)
                            )
                            .keyboardType(.numberPad)
                            .foregroundStyle(Color.appPrimaryText)
                            .multilineTextAlignment(.leading)

                            Text(store.currencyCode.rawValue)
                                .foregroundStyle(Color.appSecondaryText)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .padding()

                        Divider().background(Color.appSeparator)

                        HStack {
                            Picker("", selection: $store.currencyCode) {
                                ForEach(CurrencyCode.allCases, id: \.self) { code in
                                    Text("\(code.rawValue) - \(code.description)").tag(code)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.trailing, 15)
                        .padding(.leading, 5)
                        .padding(.vertical, 8)
                    }
                    .background(Color.appSurfaceDeep)
                    .cornerRadius(15)
                }
            }
            .listStyle(.insetGrouped)
            .scrollDismissesKeyboard(.immediately)
            .padding(0)
            .navigationTitle("custom_book_title")
            .navigationBarTitleDisplayMode(.large)
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
                    } else {
                        Button(String(localized: "create")) {
                            store.send(.saveButtonTapped)
                        }
                        .disabled(!store.isValid)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appSurface)
            .alert($store.scope(state: \.alert, action: \.alert))
            .onChange(of: selectedItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        store.send(.imageSelected(data))
                    }
                }
            }
        }
    }
}

// MARK: - Styled TextField matching BookFormView pattern

private struct CustomFormTextField: View {
    @Binding var text: String
    let placeholder: LocalizedStringKey
    var keyboardType: UIKeyboardType = .default

    init(text: Binding<String>, placeholder: String, keyboardType: UIKeyboardType = .default) {
        self._text = text
        self.placeholder = LocalizedStringKey(placeholder)
        self.keyboardType = keyboardType
    }

    var body: some View {
        TextField(
            "",
            text: $text,
            prompt: Text(placeholder).foregroundStyle(Color.appSecondaryText)
        )
        .foregroundStyle(Color.appPrimaryText)
        .keyboardType(keyboardType)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled(true)
        .padding()
        .background(Color.appSurfaceDeep)
        .cornerRadius(15)
    }
}

#Preview {
    CustomBookFormView(
        store: Store(
            initialState: CustomBookFormFeature.State(),
            reducer: { CustomBookFormFeature() }
        )
    )
}
