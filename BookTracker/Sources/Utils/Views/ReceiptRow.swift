//
//  ReceiptRow.swift
//  BookTracker
//
//  Created by 배성연 on 2/4/26.
//

import Foundation
import SwiftUI

struct ReceiptRow: Identifiable, View {
    let id: UUID
    let idx: Int
    var body: some View {
        HStack {
            VStack {
                Text("\(idx + 1).")
                    .foregroundStyle(.white.opacity(0.5)).font(.caption)
                Spacer()
            }.padding(.top, 2)
            VStack(alignment: .leading, spacing: 7.5) {
                Text("너 정말 나쁜아이구나").foregroundStyle(.white).fontWeight(.bold).font(.subheadline).lineLimit(2).truncationMode(.tail)
                HStack(spacing: 7) {
                    Text("강영숙").foregroundStyle(.white.opacity(0.75)).font(.caption)
                    Circle().frame(width: 3).foregroundStyle(.white.opacity(0.75))
                    Text("찬명교육").foregroundStyle(.white.opacity(0.75)).font(.caption2)
                }
            }
            Spacer()
        }
        .padding(.vertical, 12)
    }
}
