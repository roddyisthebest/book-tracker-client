//
//  ExternalBookDetailView.swift
//  BookTracker
//
//  Created by 배성연 on 2/16/26.
//

import ComposableArchitecture
import SwiftUI

struct ExternalBookDetailView: View {
    var store: StoreOf<ExternalBookDetailFeature>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            if let message = store.errorMessage {
                VStack {
                    Text(message)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.red)
                        .font(.system(size: 15, weight: .semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else if store.isLoading && store.book == nil {
                ProgressView()
                    .scaleEffect(1.1)
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            } else {
                ScrollView {
                    HStack(alignment: .top, spacing: 15) {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(hex: "#19191E", default: .gray))
                            .frame(width: 100, height: 150)
                            .overlay(
                                Group {
                                    if let url = store.book?.thumbnail {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView()
                                                    .tint(.secondary)
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                            case .failure:
                                                Image(systemName: "photo")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundStyle(.secondary)
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                        .frame(width: 100, height: 150)
                                        .clipShape(RoundedRectangle(cornerRadius: 15))
                                        .clipped()
                                    } else {
                                        Image(systemName: "photo")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            )

                        VStack(alignment: .leading, spacing: 10) {
                            if let book = store.book {
                                Text(book.title)
                                    .font(.system(size: 18, weight: .bold))
                                    .lineLimit(2)
                                    .truncationMode(.tail)
                                    .foregroundStyle(.white)

                                VStack(alignment: .leading, spacing: 5) {
                                    if let author = book.authors?.first {
                                        Text(author).foregroundStyle(.white.opacity(0.7)).font(.system(size: 15, weight: .semibold))
                                            .lineLimit(2)
                                            .truncationMode(.tail)
                                    }

                                    if let publisher = book.publisher {
                                        Text(publisher).foregroundStyle(.white.opacity(0.6)).font(.system(size: 12, weight: .semibold))
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                    }

                                    if let publishedDate = book.publishedDate {
                                        Text("출판일: \(publishedDate)").foregroundStyle(.white.opacity(0.6)).font(.system(size: 12, weight: .semibold))
                                            .lineLimit(1)
                                            .truncationMode(.tail).padding(.vertical, 5)
                                    }

                                    if let micros = book.saleInfo?.offers?.first?.retailPrice?.amountInMicros {
                                        let amount = Double(micros) / 1_000_000

                                        Text("\(Int(amount))원").foregroundStyle(.blue.opacity(0.6)).font(.system(size: 20, weight: .bold))
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                    }
                                }
                            }

                            Spacer()
                        }
                        Spacer()

                    }.padding(.horizontal, 15).padding(.vertical, 10)

                    Divider().background(.white.opacity(0.7))

                    VStack {
                        if let book = store.book, let desc = book.description {
                            HStack {
                                Text("책 소개").foregroundStyle(.white).font(.system(size: 22)).fontWeight(.black)
                                Spacer()
                            }
                            .padding(.vertical, 5)

                            Text(desc)
                                .multilineTextAlignment(.leading)
                                .lineLimit(store.isExtended ? 15 : 3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(Color(hex: "#C3C3C6", default: .white))

                            HStack {
                                Button(action: {
                                    store.send(.extendButtonTapped)
                                }) {
                                    Text(store.isExtended ? "접기" : "더보기")
                                }
                                Spacer()
                            }
                            .padding(.vertical, 5)
                        }

                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Button(action: {
                                    store.send(.addButtonTapped(.receipt))
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "person.text.rectangle.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(Color(hex: "#7D7DFF", default: .accentColor))
                                        Text("대출증에 추가")
                                            .foregroundStyle(Color(hex: "#9B9BA1", default: .white))
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(hex: "#19191E", default: .black))
                                    .cornerRadius(10)
                                }

                                Button(action: {
                                    store.send(.addButtonTapped(.rental))
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "receipt.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(Color(hex: "#67E9AF", default: .accentColor))
                                        Text("영수증에 추가")
                                            .foregroundStyle(Color(hex: "#9B9BA1", default: .white))
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(hex: "#19191E", default: .black))
                                    .cornerRadius(10)
                                }
                            }
                            Button(action: {
                                store.send(.addButtonTapped(.mybooks(externalId: store.id)))
                            }) {
                                HStack(spacing: 8) {
                                    let exists = store.isAlreadyRegistered
                                    Image(systemName: "books.vertical.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(
                                            exists == nil ? .gray : (exists == true ? .gray : .blue)
                                        )
                                    Text({
                                        if store.isAlreadyRegistered == nil {
                                            return "등록 여부 확인 중…"
                                        } else if store.isAlreadyRegistered == true {
                                            return "이미 등록된 책입니다"
                                        } else {
                                            return "책장에 추가하기"
                                        }
                                    }())
                                    .foregroundStyle(Color(hex: "#9B9BA1", default: .white))
                                    .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "#19191E", default: .black))
                                .cornerRadius(10)
                            }
                            .disabled(store.isAlreadyRegistered == nil || store.isAlreadyRegistered == true)
                            .overlay(alignment: .trailing) {
                                if store.isAlreadyRegistered == nil {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.secondary)
                                        .padding(.trailing, 12)
                                }
                            }
                            .animation(.easeInOut, value: store.isAlreadyRegistered)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }

                if store.isLoading {
                    ProgressView()
                        .scaleEffect(1.1)
                        .padding(16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#2C2C35", default: .black))
        .navigationTitle("도서 상세")
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
                Menu {
                    Button("수정하기", systemImage: "pencil.circle") {
//                        store.send(.updateButtonTapped)
                    }
                    Button("삭제하기", systemImage: "trash.circle") {
//                        store.send(.deleteButtonTapped)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(store: store.scope(state: \.$destination.formBook, action: \.destination.formBook)) {
            formBookStore in
            NavigationStack {
                BookFormView(store: formBookStore)
            }
        }
        .alert(store: store.scope(state: \.$destination.alert, action: \.destination.alert))
        .task {
            await store.send(.load).finish()
        }
    }
}

#Preview {
    NavigationStack {
        ExternalBookDetailView(store: Store(initialState: ExternalBookDetailFeature.State(id: ExternalBook.sample.id), reducer: {
            ExternalBookDetailFeature()
        }))
    }
}

