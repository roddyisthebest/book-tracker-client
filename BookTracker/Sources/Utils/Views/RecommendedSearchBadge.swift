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
    let keyword: String

    let onTapped: () -> Void

    var body: some View {
        Button(action: onTapped) {
            Text(keyword)
                .lineLimit(1)
                .truncationMode(.tail)
                .allowsTightening(true)
                .foregroundStyle(Color.appPrimaryText)
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
        }
        .background(Color.appSurface)
        .cornerRadius(20)
    }
}

#Preview {
    RecommendedSearchBadge(id: "23123", keyword: "괜찮아", onTapped: {})
}
