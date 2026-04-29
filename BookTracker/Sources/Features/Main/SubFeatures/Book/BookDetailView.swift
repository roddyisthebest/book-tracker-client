//
//  BookDetailView.swift
//  BookTracker
//
//  Created by 배성연 on 2/13/26.
//

import ComposableArchitecture
import Kingfisher
import SwiftUI

struct BookDetailView: View {
    @Bindable var store: Store<BookDetailFeature.State, BookDetailFeature.Action>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                if store.state.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else if let message = store.state.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.yellow)
                        Text(message)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                        Button {
                            store.send(.fetch)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                Text("retry")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    if let book = store.book {
                        ScrollView {
                            HStack(alignment: .top, spacing: 15) {
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .fill(Color.appSurfaceDeep)
                                    .frame(width: 90, height: 130)
                                    .overlay {
                                        let url = URL(string: book.imageUrl ?? "")
                                        if let url {
                                            KFImage(url)
                                                .placeholder {
                                                    ProgressView().tint(.secondary)
                                                }
                                                .retry(maxCount: 2, interval: .seconds(1))
                                                .fade(duration: 0.2)
                                                .resizable()
                                                .scaledToFill()
                                                .transition(.opacity)
                                        } else {
                                            Image(systemName: "photo")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))

                                VStack(alignment: .leading, spacing: 10) {
                                    Text(book.title)
                                        .font(.system(size: 18, weight: .bold))
                                        .lineLimit(2)
                                        .truncationMode(.tail)
                                        .foregroundStyle(Color.appPrimaryText)

                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(book.author).foregroundStyle(Color.appSecondaryText).font(.system(size: 15, weight: .semibold))
                                            .lineLimit(2)
                                            .truncationMode(.tail)
                                        Text(book.publisher).foregroundStyle(Color.appSecondaryText.opacity(0.8)).font(.system(size: 12, weight: .semibold))
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                        HStack {
                                            if book.type == .paper {
                                                Image(systemName: "book.pages.fill")
                                                    .font(.system(size: 14, weight: .semibold))
                                                Text("paper_book").font(.caption).lineLimit(1)
                                                    .truncationMode(.tail)
                                                    .foregroundStyle(Color.appPrimaryText)
                                                    .fontWeight(.semibold)

                                            } else {
                                                Image(systemName: "smartphone")
                                                    .font(.system(size: 14, weight: .semibold))
                                                Text("ebook").font(.caption).lineLimit(1)
                                                    .truncationMode(.tail)
                                                    .foregroundStyle(Color.appPrimaryText)
                                                    .fontWeight(.semibold)
                                            }
                                        }
                                        .padding(6)
                                        .padding(.horizontal, 5)
                                        .background(Color.appSurfaceDeep).cornerRadius(4)
                                        .padding(.top, 5)
                                    }
                                    Spacer()
                                }
                                Spacer()

                            }.padding(.horizontal, 15).padding(.vertical, 10)
                            Divider().background(Color.appSeparator)
                            HStack {
                                Button(action: { store.send(.viewDetailButtonTapped) }, label: {
                                    Text("view_detail")
                                    Image(systemName: "chevron.forward")
                                })

                            }.foregroundStyle(Color.appSecondaryText).font(.headline)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                            Rectangle().fill(Color.appSurfaceDeeper).frame(height: 15)

                            VStack {
                                HStack {
                                    Text("reading_record").foregroundStyle(Color.appPrimaryText).font(.system(size: 22)).fontWeight(.black)
                                    Spacer()
                                }
                                .padding(.top, 5)
                                VStack(spacing: 17.5) {
                                    StatusRow(key: String(localized: "status_label"), value: book.status.title)
                                    switch book.status {
                                    case .done:
                                        VStack(spacing: 8) {
                                            let startedDate: Date? = book.startedAt as? Date
                                            let endedDate: Date? = book.endedAt as? Date
                                            let started = startedDate?.formatted(date: .abbreviated, time: .omitted) ?? "-"
                                            let ended = endedDate?.formatted(date: .abbreviated, time: .omitted) ?? "-"
                                            StatusRow(key: String(localized: "period_label"), value: "\(started) - \(ended)")
                                        }

                                    case .dropped:
                                        VStack(spacing: 8) {
                                            let reason = (book.droppedReason?.isEmpty == false) ? (book.droppedReason ?? "") : String(localized: "no_reason")
                                            StatusRow(key: String(localized: "drop_reason_label"), value: reason)
                                        }

                                    case .reading:
                                        VStack(spacing: 8) {
                                            let readCountRaw = book.readCount ?? 0
                                            let pageCountRaw = max(book.pageCount ?? 0, 1)
                                            let progress = Int((Double(readCountRaw) / Double(pageCountRaw)) * 100.0)
                                            let pagesText = "\(readCountRaw)p"
                                            StatusRow(key: String(localized: "progress_label"), value: "\(progress)% (\(pagesText))")
                                            let memoText = (book.memo?.isEmpty == false) ? (book.memo ?? "") : String(localized: "no_memo")
                                            StatusRow(key: String(localized: "memo_label"), value: memoText)
                                        }

                                    case .want:
                                        VStack(spacing: 8) {
                                            let memoText = (book.memo?.isEmpty == false) ? (book.memo ?? "") : String(localized: "no_memo")
                                            StatusRow(key: String(localized: "memo_label"), value: memoText)
                                        }
                                    }
                                }
                                .padding(.vertical, 10)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical)

                            Rectangle().fill(Color.appSurfaceDeeper).frame(height: 15)

                            VStack {
                                HStack {
                                    Text("change_status").foregroundStyle(Color.appPrimaryText).font(.system(size: 22)).fontWeight(.black)
                                    Spacer()
                                }
                                .padding(.top, 5)
                                VStack(spacing: 12) {
                                    HStack(spacing: 12) {
                                        if book.status != .done {
                                            Button(action: { store.send(.changeStatusButtonTapped(.done)) }) {
                                                HStack(spacing: 8) {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.system(size: 16, weight: .semibold))
                                                        .foregroundStyle(.green)
                                                    Text("finished_reading")
                                                        .foregroundStyle(Color.appSecondaryText)
                                                        .fontWeight(.semibold)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(Color.appButtonSurface)
                                                .cornerRadius(10)
                                            }
                                        }

                                        if book.status != .dropped {
                                            Button(action: { store.send(.changeStatusButtonTapped(.dropped)) }) {
                                                HStack(spacing: 8) {
                                                    Image(systemName: "multiply.circle.fill")
                                                        .font(.system(size: 16, weight: .semibold))
                                                        .foregroundStyle(.red)
                                                    Text("stop_reading")
                                                        .foregroundStyle(Color.appSecondaryText)
                                                        .fontWeight(.semibold)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(Color.appButtonSurface)
                                                .cornerRadius(10)
                                            }
                                        }
                                    }

                                    if book.status != .reading {
                                        Button(action: { store.send(.changeStatusButtonTapped(.reading)) }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "apple.books.pages.fill")
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundStyle(.blue)
                                                Text("currently_reading")
                                                    .foregroundStyle(Color.appSecondaryText)
                                                    .fontWeight(.semibold)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.appButtonSurface)
                                            .cornerRadius(10)
                                        }
                                    }
                                }
                                .padding(.vertical, 10)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical)
                        } // end ScrollView
                    } else {
                        EmptyView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appSurface)
            .navigationTitle("book_detail")
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
                    if store.state.isDeleting {
                        ProgressView()
                            .progressViewStyle(.circular)

                    } else {
                        Menu {
                            Button(String(localized: "edit"), systemImage: "pencil.circle") {
                                store.send(.updateButtonTapped)
                            }
                            Button(String(localized: "delete"), systemImage: "trash.circle") {
                                store.send(.deleteButtonTapped)
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(item: $store.scope(state: \.destination?.formBook, action: \.destination.formBook)) { formBookStore in
                BookFormView(store: formBookStore)
            }
            .sheet(item: $store.scope(state: \.destination?.bookInfo, action: \.destination.bookInfo)) { bookInfoStore in
                NavigationStack {
                    BookInfoView(store: bookInfoStore)
                }
            }
            .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
            .task {
                store.send(.onAppear)
            }
        }
    }
}

#Preview {
    let previewID = UUID(uuidString: "0dd5c85b-b058-45d6-871e-fb3e1e0f33bd") ?? UUID()
    return BookDetailView(store: Store(initialState: BookDetailFeature.State(id: previewID), reducer: {
        BookDetailFeature()
    }))
}

