//
//  ExternalBookRow.swift
//  BookTracker
//
//  Created by 배성연 on 2/17/26.
//

import SwiftUI

struct ExternalBookRow: View {
    let book: ExternalBook
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading) {
                Text(book.title)
                    .font(.system(size: 18, weight: .bold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(.white)

                HStack(alignment: .top, spacing: 10) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "#2A2A33", default: .gray))
                        .frame(width: 80, height: 100)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("마가렛 렌클").foregroundStyle(.white.opacity(0.7)).font(.system(size: 14, weight: .semibold))
                            .lineLimit(2)
                            .truncationMode(.tail)
                        Text("을유문화사").foregroundStyle(.white.opacity(0.6)).font(.system(size: 11, weight: .semibold))
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()

                        Text("5,500원").fontWeight(.semibold)
                    }
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(hex: "#17171C"))
        .cornerRadius(10)
    }
}

#Preview("SelectBookRow Samples") {
    VStack(spacing: 16) {
        ExternalBookRow(
            book: ExternalBook(id: "21232", title: "다만묻고싶어"),
            onTap: {},
        )

        ExternalBookRow(
            book: ExternalBook(id: "21232", title: "서로가 마지막이 되길 우린 약속했지만 그저 스쳐간 인연"),
            onTap: {},
        )
    }
    .padding()
    .background(.black)
}
