//
//  MyBookList.swift
//  BookTracker
//
//  Created by 배성연 on 2/15/26.
//

import ComposableArchitecture
import SwiftUI

struct MyBookList: View {
    @Bindable var store: StoreOf<MyBookListFeature>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                content
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "#101013", default: .black))
            .navigationTitle("책장")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sheet(store: store.scope(state: \.$destination.viewBookDetail, action: \.destination.viewBookDetail)) { bookDetailStore in
                BookDetailView(store: bookDetailStore)
            }
            .alert(store: store.scope(state: \.$destination.alert, action: \.destination.alert))
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
            Menu {
                Picker("정렬", selection: $store.sortOption) {
                    Text("오래된순").tag(BookSortOption.oldest)
                    Text("최신순").tag(BookSortOption.newest)
                    Text("제목순(가나다)").tag(BookSortOption.titleAsc)
                    Text("제목순(반대)").tag(BookSortOption.titleDesc)
                }
                .pickerStyle(.inline)

                Divider()

                Button(role: .destructive, action: {
//                    store.send(.allDeleteButtonTapped)

                }) {
                    Label("전체 삭제", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    private var content: some View {
        VStack {
            segmentedPicker
            list
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var segmentedPicker: some View {
        Picker("탭", selection: $store.bookStatus) {
            Text("완독(5)").tag(BookStatus.done)
            Text("읽는 중").tag(BookStatus.reading)
            Text("읽는 싶은").tag(BookStatus.want)
            Text("읽는 만").tag(BookStatus.dropped)
        }
        .pickerStyle(.segmented)
        .controlSize(.large)
        .padding(.horizontal)
        .onAppear {
            // 선택된 세그먼트의 pill 배경색
            UISegmentedControl.appearance().selectedSegmentTintColor = UIColor.systemBlue

            // (옵션) 텍스트 색상/두께/크기 조절
            let selectedAttrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 17, weight: .bold)
            ]
            let normalAttrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white.withAlphaComponent(0.8),
                .font: UIFont.systemFont(ofSize: 17, weight: .medium)
            ]
            UISegmentedControl.appearance().setTitleTextAttributes(normalAttrs, for: .normal)
            UISegmentedControl.appearance().setTitleTextAttributes(selectedAttrs, for: .selected)
        }
        .onDisappear {
            // 필요 시 원복 (전역 Appearance 영향 최소화)
            UISegmentedControl.appearance().selectedSegmentTintColor = nil
            UISegmentedControl.appearance().setTitleTextAttributes(nil, for: .normal)
            UISegmentedControl.appearance().setTitleTextAttributes(nil, for: .selected)
        }
        .padding(.bottom, 10)
    }

    private var list: some View {
        ScrollView {
            LazyVStack {
                ForEach(store.books, id: \.id) { book in
                    BookRow(
                        book: book,
                        onTap: {
                            store.send(.bookCardTapped(id: book.id))
                        },
                        onDelete: {
                            store.send(.deleteButtonTapped(id: book.id))
                        }
                    )
                }
            }
            .padding(.horizontal, 15).padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    MyBookList(store: Store(initialState: MyBookListFeature.State(), reducer: {
        MyBookListFeature()
    }))
}
