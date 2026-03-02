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
                ScrollView {
                    HStack(alignment: .top, spacing: 15) {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(hex: "#19191E", default: .gray))
                            .frame(width: 90, height: 130)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            )

                        VStack(alignment: .leading, spacing: 10) {
                            Text("smsasdsdfkas")
                                .font(.system(size: 18, weight: .bold))
                                .lineLimit(2)
                                .truncationMode(.tail)
                                .foregroundStyle(.white)

                            VStack(alignment: .leading, spacing: 5) {
                                Text("강영숙").foregroundStyle(.white.opacity(0.7)).font(.system(size: 15, weight: .semibold))
                                    .lineLimit(2)
                                    .truncationMode(.tail)
                                Text("한얼교육").foregroundStyle(.white.opacity(0.6)).font(.system(size: 12, weight: .semibold))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                HStack {
                                    Image(systemName: "book.pages.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("종이책").font(.caption).lineLimit(1)
                                        .truncationMode(.tail)
                                        .foregroundStyle(.white)
                                        .fontWeight(.semibold)
                                }
                                .padding(6)
                                .padding(.horizontal, 5)
                                .background(Color(hex: "#19191E", default: .gray)).cornerRadius(4)
                                .padding(.top, 5)
                            }
                            Spacer()
                        }
                        Spacer()

                    }.padding(.horizontal, 15).padding(.vertical, 10)
                    Divider().background(.white.opacity(0.7))
                    HStack {
                        Button(action: {}, label: {
                            Text("자세히 보기")
                            Image(systemName: "chevron.forward")
                        })

                    }.foregroundStyle(.white.opacity(0.6)).font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                    Divider().frame(height: 15).background(.black.opacity(0.6))

                    VStack {
                        HStack {
                            Text("독서기록").foregroundStyle(.white).font(.system(size: 22)).fontWeight(.black)
                            Spacer()
                        }
                        .padding(.top, 5)
                        VStack(spacing: 17.5) {
                            StatusRow(key: "상태", value: "읽고 싶은책")
                            StatusRow(key: "진행률", value: "23%")
                            StatusRow(key: "메모", value: "안녕하세요 저는 미켈란젤로 입니다. 사람들은 이리 말하고 저리말하지")
                        }
                        .padding(.vertical, 10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical)

                    Divider().frame(height: 15).background(.black.opacity(0.6))

                    VStack {
                        HStack {
                            Text("상태변경").foregroundStyle(.white).font(.system(size: 22)).fontWeight(.black)
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
                                            .foregroundStyle(Color(hex: "#9B9BA1", default: .white))
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(hex: "#19191E", default: .black))
                                    .cornerRadius(10)
                                }

                                Button(action: {}) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "multiply.circle.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(.red)
                                        Text("그만 읽고싶어요")
                                            .foregroundStyle(Color(hex: "#9B9BA1", default: .white))
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(hex: "#19191E", default: .black))
                                    .cornerRadius(10)
                                }
                            }
                            Button(action: {}) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(Color(hex: "#00FFB2", default: .blue))
                                    Text("책을 반납했어요")
                                        .foregroundStyle(Color(hex: "#9B9BA1", default: .white))
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "#19191E", default: .black))
                                .cornerRadius(10)
                            }
                            Button(action: {}) {
                                HStack(spacing: 8) {
                                    Image(systemName: "apple.books.pages.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.blue)
                                    Text("읽고있어요")
                                        .foregroundStyle(Color(hex: "#9B9BA1", default: .white))
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "#19191E", default: .black))
                                .cornerRadius(10)
                            }
                        }
                        .padding(.vertical, 10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "#2C2C35", default: .black))
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
            .sheet(item: $store.scope(state: \.destination?.formBook, action: \.destination.formBook)) { formBookStore in
                BookFormView(store: formBookStore)
            }
            .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
        }
    }
}

#Preview {
    BookDetailView(store: Store(initialState: BookDetailFeature.State(), reducer: {
        BookDetailFeature()
    }))
}
