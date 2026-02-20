//
//  ReceiptSelectBooksView.swift
//  BookTracker
//
//  Created by 배성연 on 2/20/26.
//
import ComposableArchitecture
import SwiftUI

private struct BookRowView: View {
    let title: String
    let author: String
    let publisher: String
    let isbn: String
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        DeleteExternalBookRow(
            title: title,
            author: author,
            publisher: publisher,
            isbn: isbn,
            onTap: onTap,
            onDelete: onDelete
        )
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 7.5, leading: 20, bottom: 7.5, trailing: 20))
        .background(Color(hex: "#17171C"))
        .cornerRadius(10)
    }
}

struct ReceiptSelectBooksView: View {
    @Bindable var store: StoreOf<ReceiptSelectBooksFeature>
    @Environment(\.dismiss) private var dismiss

    private typealias Feature = ReceiptSelectBooksFeature

    @ViewBuilder
    private var booksList: some View {
        List {
            ForEach(store.externalBooks, id: \.id) { book in
                BookRowView(
                    title: book.title,
                    author: "저자",
                    publisher: "publisher",
                    isbn: "52434341234134134234234",
                    onTap: {},
                    onDelete: { store.send(.deleteButtonTapped(id: book.id)) },
                )
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .listRowBackground(Color.clear)
        .background(Color(hex: "#2C2C35", default: .black))
    }

    var body: some View {
        booksList
            .navigationTitle("대출증 발급")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .navigationSubtitle("책을 추가하여 대출증을 발급해보세요.")
            .toolbar { toolbarContent }
            .overlay(alignment: .bottom) { bottomBar }
            .sheet(
                item: $store.scope(state: \.destination?.issueReceipt, action: \.destination.issueReceipt)
            ) { issueReceiptStore in
                NavigationStack {
                    IssueReceiptView(store: issueReceiptStore)
                }
            }
            .sheet(
                item: $store.scope(state: \.destination?.search, action: \.destination.search)
            ) { searchStore in
                NavigationStack {
                    SearchView(store: searchStore)
                }
            }
            .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                Label("뒤로가기", systemImage: "chevron.left")
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button("발급하기") {
                store.send(.issueButtonTapped)
            }
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        HStack(spacing: 10) {
            DefaultButton(action: {
                store.send(.addButtonTapped)
            }) { Text("추가하기") }
        }
        .padding(.horizontal, 25)
    }
}

#Preview {
    NavigationStack {
        ReceiptSelectBooksView(store: Store(initialState: ReceiptSelectBooksFeature.State(), reducer: {
            ReceiptSelectBooksFeature()
        }))
    }
}
