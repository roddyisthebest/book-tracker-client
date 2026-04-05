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
            FormCard(labelText: "독서기간") { DateSectionView(store: store) }
            FormCard(labelText: "진행률") {
                ProgressSectionView(store: store)
            }
            FormCard(labelText: "메모") { MemoSectionView(store: store) }
        }
        if case .done = store.status {
            FormCard(labelText: "독서기간") { DateRangeSectionView(store: store) }
            FormCard(labelText: "별점 (옆으로 스크롤 가능)") { RatingSectionView(store: store) }

            FormCard(labelText: "리뷰") { ReviewSectionView(store: store) }
        }
        if case .want = store.status {
            FormCard(labelText: "메모") { MemoSectionView(store: store) }
        }
        if case .dropped = store.status {
            FormCard(labelText: "중단이유") { ReasonSectionView(store: store) }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                FormCard(labelText: "책종류") { TypeSectionView(store: store) }
                FormCard(labelText: "상태") { StatusSectionView(store: store) }

                statusSpecific
            }
            .listStyle(.plain)
            .padding(0)
            .listStyle(.insetGrouped)
            .navigationTitle(store.isEditing ? "책 수정" : "책 추가")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label("뒤로가기", systemImage: "chevron.left")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if store.isLoading {
                        ProgressView()
                    } else if store.isEditing {
                        Button("저장하기") {
                            store.send(.saveButtonTapped)
                        }
                    } else {
                        Button("생성하기") {
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

#Preview {
    BookFormView(
        store: Store(
            initialState: BookFormFeature.State(externalId: "", bookId: UUID(1)),
            reducer: { BookFormFeature() }
        )
    )
}
