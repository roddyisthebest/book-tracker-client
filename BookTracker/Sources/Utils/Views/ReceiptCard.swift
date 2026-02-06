//
//  ReceiptCard.swift
//  BookTracker
//
//  Created by 배성연 on 2/5/26.
//

import SwiftUI

struct ReceiptCard: View {
    let receipt: Receipt
    let onTapped: (() -> Void)?
    let onDelete: (() -> Void)?

    var body: some View {
        let isRental = receipt.type == .rental

        Button(action: {
            if let onTapped {
                onTapped()
            }
        }) {
            VStack(spacing: 10) {
                HStack {
                    if isRental {
                        HStack {
                            Image(systemName: "person.text.rectangle.fill")
                                .font(.system(size: 15, weight: .semibold)).foregroundStyle(Color(hex: "#7D7DFF", default: .accentColor))
                            Text("대출증").foregroundStyle(Color(hex: "#7D7DFF", default: .accentColor)).font(.system(size: 14, weight: .bold))

                        }.padding(10).background(Color(hex: "#202045")).cornerRadius(15)
                    }
                    else {
                        HStack {
                            Image(systemName: "receipt.fill")
                                .font(.system(size: 13, weight: .semibold)).foregroundStyle(Color(hex: "#67E9AF", default: .accentColor))
                            Text("영수증").foregroundStyle(Color(hex: "#67E9AF", default: .accentColor)).font(.system(size: 14, weight: .bold))
                        }.padding(10).background(Color(hex: "#384B43")).cornerRadius(15)
                    }
                    Spacer()
                }

                HStack(spacing: 2.5) {
                    Text(receipt.title)
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text("외 20건")
                        .foregroundStyle(.white)
                        .fontWeight(.bold).layoutPriority(1) //

                    Spacer()
                }.padding(.vertical, 7).padding(.leading, 5)

                HStack(spacing: 5) {
                    if isRental {
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 14)).foregroundStyle(Color(hex: "#7D7DFF", default: .accentColor))

                        Text("우리도서관").font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                    }
                    else {
                        Image(systemName: "wonsign")
                            .font(.system(size: 14)).foregroundStyle(Color(hex: "#67E9AF", default: .accentColor))

                        Text("12,000원").font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                    }

                    Spacer()
                }.padding(.leading, 3)

                HStack {
                    Text("2026년 1월 13일").foregroundStyle(.white.opacity(0.6)).font(.system(size: 14))
                    Spacer()
                }.padding(.leading, 5)

            }.frame(maxWidth: .infinity, maxHeight: .infinity).padding(.horizontal, 10).padding(.vertical, 15).background(Color(hex: "#33353D")).cornerRadius(10)
        }
//        .buttonStyle(ScalableButtonStyle(pressedScale: 0.95))
        .contextMenu {
            Button(role: .destructive) {
                onDelete?()
            } label: {
                Label("삭제", systemImage: "trash")
            }

            // 필요하면 다른 메뉴도 추가 가능 (예: 공유)
            Button {
                // 공유 등 다른 액션
            } label: {
                Label("공유", systemImage: "square.and.arrow.up")
            }
        }
    }
}
