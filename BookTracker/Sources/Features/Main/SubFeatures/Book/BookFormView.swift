//
//  CollectionFormView.swift
//  BookTracker
//
//  Created by 배성연 on 2/7/26.
//
import ComposableArchitecture
import SwiftUI

struct BookFormView: View {
    @Bindable var store: StoreOf<BookFormFeature>
    @Environment(\.dismiss) private var dismiss

    @ViewBuilder
    private var statusSpecific: some View {
        if case .reading = store.status {
            FormCard(labelText: String(localized: "reading_period_label")) { DateSectionView(store: store) }
            FormCard(labelText: String(localized: "progress_label")) {
                ProgressSectionView(store: store)
            }
            FormCard(labelText: String(localized: "memo_label")) { MemoSectionView(store: store) }
        }
        if case .done = store.status {
            FormCard(labelText: String(localized: "reading_period_label")) { DateRangeSectionView(store: store) }
            FormCard(labelText: String(localized: "rating_label")) { RatingSectionView(store: store) }

            FormCard(labelText: String(localized: "review_label")) { ReviewSectionView(store: store) }
        }
        if case .want = store.status {
            FormCard(labelText: String(localized: "memo_label")) { MemoSectionView(store: store) }
        }
        if case .dropped = store.status {
            FormCard(labelText: String(localized: "drop_reason_label")) { ReasonSectionView(store: store) }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if !store.isChangeModeActive {
                    FormCard(labelText: String(localized: "book_type_label")) { TypeSectionView(store: store) }
                    FormCard(labelText: String(localized: "status_label")) { StatusSectionView(store: store) }
                }

                statusSpecific
            }
            .conditionalListStyle(isPlain: store.isChangeModeActive)
            .scrollDismissesKeyboard(.interactively)
            .padding(0)
            .navigationTitle(store.title)
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
                    } else if store.isEditing {
                        Button(String(localized: "update")) {
                            store.send(.saveButtonTapped)
                        }
                    } else {
                        Button(String(localized: "create")) {
                            store.send(.addButtonTapped)
                        }
                    }
                }
            }
            .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
            .scrollContentBackground(.hidden) // 추가
            .background(Color.appSurface)
        }
    }
}

private extension View {
    @ViewBuilder
    func conditionalListStyle(isPlain: Bool) -> some View {
        if isPlain {
            self.listStyle(.plain)
        } else {
            self.listStyle(.insetGrouped)
        }
    }
}

#Preview {
    BookFormView(
        store: Store(
            initialState: BookFormFeature.State(externalId: "", bookId: UUID(1)),
            reducer: { BookFormFeature() }
        )
    )
}
