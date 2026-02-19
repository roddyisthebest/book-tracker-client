//
//  RecommendedSearchBadge.swift
//  BookTracker
//
//  Created by 배성연 on 2/17/26.
//

import Foundation
import SwiftUI

struct RecommendedSearchBadge: View {
    let id: String
    let book: ExternalBook

    let onTapped: () -> Void

    var body: some View {
        Button(action: onTapped) {
            Text(book.title)
                .lineLimit(1)
                .truncationMode(.tail)
                .allowsTightening(true)
                .foregroundStyle(.white)
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
        }
        .background(Color(hex: "#2C2C35", default: .black))
        .cornerRadius(20)
    }
}

#Preview {
    RecommendedSearchBadge(id: "23123", book: ExternalBook(id: "asd", title: "괜찮아.. 괜찮아"), onTapped: {})
}
