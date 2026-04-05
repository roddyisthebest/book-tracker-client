//
//  BookDetailView.swift
//  BookTracker
//
//  Created by 배성연 on 2/13/26.
//

import ComposableArchitecture
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
                                Text("다시 가져오기")
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
                                            AsyncImage(url: url) { phase in
                                                switch phase {
                                                case .empty:
                                                    Image(systemName: "photo")
                                                        .font(.system(size: 14, weight: .semibold))
                                                        .foregroundStyle(.secondary)

                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                        .transition(.opacity)

                                                case .failure:
                                                    Image(systemName: "photo")
                                                        .font(.system(size: 14, weight: .semibold))
                                                        .foregroundStyle(.secondary)

                                                @unknown default:
                                                    Image(systemName: "photo")
                                                        .font(.system(size: 14, weight: .semibold))
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
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
                                                Text("종이책").font(.caption).lineLimit(1)
                                                    .truncationMode(.tail)
                                                    .foregroundStyle(Color.appPrimaryText)
                                                    .fontWeight(.semibold)

                                            } else {
                                                Image(systemName: "smartphone")
                                                    .font(.system(size: 14, weight: .semibold))
                                                Text("전자책").font(.caption).lineLimit(1)
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
                                Button(action: {}, label: {
                                    Text("자세히 보기")
                                    Image(systemName: "chevron.forward")
                                })

                            }.foregroundStyle(Color.appSecondaryText).font(.headline)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                            Rectangle().fill(Color.appSurfaceDeeper).frame(height: 15)

                            VStack {
                                HStack {
                                    Text("독서기록").foregroundStyle(Color.appPrimaryText).font(.system(size: 22)).fontWeight(.black)
                                    Spacer()
                                }
                                .padding(.top, 5)
                                VStack(spacing: 17.5) {
                                    StatusRow(key: "상태", value: book.status.title)
                                    switch book.status {
                                    case .done:
                                        VStack(spacing: 8) {
                                            let startedDate: Date? = book.startedAt as? Date
                                            let endedDate: Date? = book.endedAt as? Date
                                            let started = startedDate?.formatted(date: .abbreviated, time: .omitted) ?? "-"
                                            let ended = endedDate?.formatted(date: .abbreviated, time: .omitted) ?? "-"
                                            StatusRow(key: "기간", value: "\(started) - \(ended)")
                                        }

                                    case .dropped:
                                        VStack(spacing: 8) {
                                            let reason = (book.droppedReason?.isEmpty == false) ? (book.droppedReason ?? "") : "사유 없음"
                                            StatusRow(key: "중단이유", value: reason)
                                        }

                                    case .reading:
                                        VStack(spacing: 8) {
                                            let readCountRaw = book.readCount ?? 0
                                            let pageCountRaw = max(book.pageCount ?? 0, 1)
                                            let progress = Int((Double(readCountRaw) / Double(pageCountRaw)) * 100.0)
                                            let pagesText = "\(readCountRaw)p"
                                            StatusRow(key: "진행률", value: "\(progress)% (\(pagesText))")
                                            let memoText = (book.memo?.isEmpty == false) ? (book.memo ?? "") : "메모 없음"
                                            StatusRow(key: "메모", value: memoText)
                                        }

                                    case .want:
                                        VStack(spacing: 8) {
                                            let memoText = (book.memo?.isEmpty == false) ? (book.memo ?? "") : "메모 없음"
                                            StatusRow(key: "메모", value: memoText)
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
                                    Text("상태변경").foregroundStyle(Color.appPrimaryText).font(.system(size: 22)).fontWeight(.black)
                                    Spacer()
                                }
                                .padding(.top, 5)
                                VStack(spacing: 12) {
                                    HStack(spacing: 12) {
                                        Button(action: {}) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundStyle(.green)
                                                Text("다 읽었어요")
                                                    .foregroundStyle(Color.appSecondaryText)
                                                    .fontWeight(.semibold)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.appButtonSurface)
                                            .cornerRadius(10)
                                        }

                                        Button(action: {}) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "multiply.circle.fill")
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundStyle(.red)
                                                Text("그만 읽고싶어요")
                                                    .foregroundStyle(Color.appSecondaryText)
                                                    .fontWeight(.semibold)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.appButtonSurface)
                                            .cornerRadius(10)
                                        }
                                    }
                                    Button(action: {}) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color(hex: "#00FFB2", default: .blue))
                                            Text("책을 반납했어요")
                                                .foregroundStyle(Color.appSecondaryText)
                                                .fontWeight(.semibold)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.appButtonSurface)
                                        .cornerRadius(10)
                                    }
                                    Button(action: {}) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "apple.books.pages.fill")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundStyle(.blue)
                                            Text("읽고있어요")
                                                .foregroundStyle(Color.appSecondaryText)
                                                .fontWeight(.semibold)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.appButtonSurface)
                                        .cornerRadius(10)
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
            .navigationTitle("책 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label("뒤로가기", systemImage: "chevron.left")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if store.state.isDeleting {
                        ProgressView()
                            .progressViewStyle(.circular)

                    } else {
                        Menu {
                            Button("수정하기", systemImage: "pencil.circle") {
                                store.send(.updateButtonTapped)
                            }
                            Button("삭제하기", systemImage: "trash.circle") {
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
