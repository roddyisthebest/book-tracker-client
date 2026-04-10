//
//  ReceiptSelectBooksView.swift
//  BookTracker
//
//  Created by 배성연 on 2/20/26.
//
import ComposableArchitecture
import SwiftUI

private struct BookRowView: View {
    let book: ReceiptBook
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        DeleteReceiptBookRow(
            book: book,
            onTap: onTap,
            onDelete: onDelete
        )
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 7.5, leading: 20, bottom: 7.5, trailing: 20))
        .background(Color.clear)
    }
}

private struct ReceiptBooksLoadingView: View {
    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(.white)

            Text("loading_books")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.appSecondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ReceiptBooksErrorView: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.yellow)

            Text("book_list_load_failed")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.appPrimaryText)

            Text("try_again_later")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.appSecondaryText)

            Button(action: onRetry) {
                Text("retry")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: 180)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .foregroundStyle(.black)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ReceiptBooksEmptyView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "books.vertical")
                .font(.system(size: 28))
                .foregroundStyle(Color.appSecondaryText)

            Text("no_books_added")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.appPrimaryText)

            Text("add_books_to_start")
                .font(.system(size: 13, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.appSecondaryText)

            Button(action: onAdd) {
                Text("add_books")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: 180)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .foregroundStyle(.black)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct FullScreenLoadingOverlay: View {
    let title: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.1)

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.appPrimaryText)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(Color.appSurfaceDeep)
            .cornerRadius(14)
        }
    }
}

struct ReceiptSelectBooksView: View {
    @Bindable var store: StoreOf<ReceiptSelectBooksFeature>
    @Environment(\.dismiss) private var dismiss

    @ViewBuilder
    private var contentView: some View {
        if store.isFetching && store.books.isEmpty && !store.isError {
            ReceiptBooksLoadingView()
        } else if store.isError && store.books.isEmpty {
            ReceiptBooksErrorView {
                store.send(.onRefresh)
            }
        } else if store.books.isEmpty {
            ReceiptBooksEmptyView {
                store.send(.addButtonTapped)
            }
        } else {
            booksList
        }
    }

    @ViewBuilder
    private var booksList: some View {
        List {
            ForEach(store.books, id: \.id) { book in
                BookRowView(
                    book: book,
                    onTap: {},
                    onDelete: { store.send(.deleteButtonTapped(id: book.id)) }
                )
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.appSurface)
        .refreshable {
            store.send(.onRefresh)
        }
        .overlay(alignment: .top) {
            if store.isFetching {
                ProgressView()
                    .tint(.white)
                    .padding(.top, 8)
            }
        }
    }

    var body: some View {
        contentView
            .background(Color.appSurface.ignoresSafeArea())
            .navigationTitle(store.type == .purchase ? "issue_purchase_receipt" : "issue_rental_receipt")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .navigationSubtitle(
                store.type == .purchase
                    ? String(localized: "receipt_subtitle_purchase")
                    : String(localized: "receipt_subtitle_rental")
            )
            .toolbar { toolbarContent }
            .overlay(alignment: .bottom) {
                if !store.books.isEmpty {
                    bottomBar
                }
            }
            .overlay {
                if store.isDeleting {
                    FullScreenLoadingOverlay(title: String(localized: "deleting"))
                }
            }
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
            .task {
                store.send(.onAppear)
            }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                Label("back", systemImage: "chevron.left")
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button(String(localized: "issue")) {
                store.send(.issueButtonTapped)
            }
            .disabled(store.books.isEmpty || store.isFetching)
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        HStack(spacing: 10) {
            DefaultButton(action: {
                store.send(.addButtonTapped)
            }) {
                Text("add")
            }
        }
        .padding(.horizontal, 25)
        .padding(.bottom, 10)
    }
}

#Preview {
    NavigationStack {
        ReceiptSelectBooksView(
            store: Store(
                initialState: ReceiptSelectBooksFeature.State(),
                reducer: {
                    ReceiptSelectBooksFeature()
                }
            )
        )
    }
}
