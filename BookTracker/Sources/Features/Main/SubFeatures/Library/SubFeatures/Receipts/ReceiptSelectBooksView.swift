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

            Text("책 목록을 불러오는 중이에요.")
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

            Text("책 목록을 불러오지 못했어요.")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.appPrimaryText)

            Text("잠시 후 다시 시도해주세요.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.appSecondaryText)

            Button(action: onRetry) {
                Text("다시 시도")
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

            Text("추가된 책이 없어요.")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.appPrimaryText)

            Text("책을 추가해서 영수증이나 대출증 발급을 시작해보세요.")
                .font(.system(size: 13, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.appSecondaryText)

            Button(action: onAdd) {
                Text("책 추가하기")
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
            .navigationTitle(store.type == .purchase ? "영수증 발급" : "대출증 발급")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .navigationSubtitle(
                store.type == .purchase
                    ? "책을 추가하여 영수증을 발급해보세요."
                    : "책을 추가하여 대출증을 발급해보세요."
            )
            .toolbar { toolbarContent }
            .overlay(alignment: .bottom) {
                if !store.books.isEmpty {
                    bottomBar
                }
            }
            .overlay {
                if store.isDeleting {
                    FullScreenLoadingOverlay(title: "삭제 중이에요...")
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
                Label("뒤로가기", systemImage: "chevron.left")
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button("발급하기") {
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
                Text("추가하기")
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
