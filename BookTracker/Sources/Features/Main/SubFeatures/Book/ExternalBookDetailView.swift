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
            ScrollView {
                HStack(alignment: .top, spacing: 15) {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(hex: "#19191E", default: .gray))
                        .frame(width: 100, height: 150)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                        )

                    VStack(alignment: .leading, spacing: 10) {
                        Text("smsasdsdfkassmsasdsdfkassmsasdsdfkassmsasdsdfkas")
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

                            Text("출판일: 2021-02-28").foregroundStyle(.white.opacity(0.6)).font(.system(size: 12, weight: .semibold))
                                .lineLimit(1)
                                .truncationMode(.tail).padding(.vertical, 5)

                            Text("5,000원").foregroundStyle(.blue.opacity(0.6)).font(.system(size: 20, weight: .bold))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        Spacer()
                    }
                    Spacer()

                }.padding(.horizontal, 15).padding(.vertical, 10)

                Divider().background(.white.opacity(0.7))

                VStack {
                    HStack {
                        Text("책 소개").foregroundStyle(.white).font(.system(size: 22)).fontWeight(.black)
                        Spacer()
                    }
                    .padding(.top, 5)

                    Text("""
                    누구도 도와줄 수 없는 상황, 혼자 헤쳐나가야 한다
                    지켜야 할 약속, 붙잡고 싶은 온기
                    김영하가 『살인자의 기억법』 이후 9 년 만에 내놓는 장편소설 『작별인사』는 그리 멀지 않은 미래를 배경으로, 별안간 삶이 송두리째 뒤흔들린 한 소년의 여정을 좇는다. 유명한 IT 기업의 연구원인 아버지와 쾌적하고 평화롭게 살아가던 철이는 어느날 갑자기 수용소로 끌려가 난생처음 날것의 감정으로 가득한 혼돈의 세계에 맞닥뜨리게 되면서 정신적, 신체적 위기에 직면한다. 동시에 자신처럼 사회에서 배제된 자들을 만나 처음으로 생생한 소속감을 느끼고 따뜻한 우정도 싹틔운다. 철이는 그들과 함께 수용소를 탈출하여 집으로 돌아가기 위해 길을 떠나지만 그 여정에는 피할 수 없는 질문이 기다리고 있다.
                    """)
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
                    .padding(.top, 5)

                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Button(action: {
                                store.send(.addButtonTapped(.rental))
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
                                store.send(.addButtonTapped(.receipt))
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
                            store.send(.addButtonTapped(.mybooks))
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "books.vertical.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.blue)
                                Text("책장에 추가하기")
                                    .foregroundStyle(Color(hex: "#9B9BA1", default: .white))
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "#19191E", default: .black))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.vertical)
                }
                .padding(.horizontal, 20)
                .padding(.vertical)
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
            BookFormView(store: formBookStore)
        }
        .alert(store: store.scope(state: \.$destination.alert, action: \.destination.alert))
    }
}

#Preview {
    NavigationStack {
        ExternalBookDetailView(store: Store(initialState: ExternalBookDetailFeature.State(id: "as"), reducer: {
            ExternalBookDetailFeature()
        }))
    }
}
