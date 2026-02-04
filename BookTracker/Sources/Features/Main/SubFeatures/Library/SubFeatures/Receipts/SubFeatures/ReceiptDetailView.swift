//
//  ReceiptDetailView.swift
//  BookTracker
//
//  Created by 배성연 on 2/3/26.
//

import ComposableArchitecture
import SwiftUI

struct ReceiptDetailView: View {
    @Bindable var store: StoreOf<ReceiptDetailFeature>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header at top
            ZStack {
                Text("영수증")
                    .font(.headline)
                    .foregroundStyle(.white)

                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
                    }
                    Spacer()
                }
            }
            .frame(height: 52)
            .padding(.horizontal)

            ZStack {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(0 ..< 5, id: \.self) { idx in
                            ReceiptRow(id: UUID(), idx: idx)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                    // divider
                    Divider().background(.white.opacity(0.7))
                    HStack {
                        Spacer()
                        Text("총 2권").foregroundStyle(.white).font(.headline)
                    }.padding(.horizontal, 20)
                        .padding(.vertical, 8)
                    Divider().frame(height: 15).background(.black.opacity(0.8))

                    VStack {
                        HStack {
                            Text("상태값").foregroundStyle(.white).font(.system(size: 25)).fontWeight(.black)
                            Spacer()
                        }.padding(.top, 5)
                        VStack(spacing: 17.5) {
                            StatusRow(key: "대출날짜", value: "2026년 02월 01일")
                            StatusRow(key: "반납날짜", value: "2026년 02월 01일")
                            StatusRow(key: "도서관", value: "이지메 도서관")
                        }.padding(.vertical, 10).padding(.bottom, 80)
                    }.padding(.horizontal, 20).padding(.vertical)
                }
                VStack {
                    Spacer()
                    DefaultButton(action: {
                        store.send(.deleteButtonTapped(id: UUID(1)))
                    }, label: { Text("삭제하기") })
                        .padding(.vertical, 12)
                }

            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#2C2C35", default: .black))
        .alert($store.scope(state: \.alert, action:
            \.alert))
    }
}

#Preview {
    ReceiptDetailView(store: Store(initialState: ReceiptDetailFeature.State(recepit: "idid"), reducer: {
        ReceiptDetailFeature()
    }))
}
