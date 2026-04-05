//
//  SearchBadge.swift
//  BookTracker
//
//  Created by 배성연 on 2/17/26.
//

import Foundation
import SwiftUI

struct SearchBadge: View {
    let id: String
    let text: String
    let onTapped: () -> Void
    let onDeleted: () -> Void

    var body: some View {
        Button(action: onTapped) {
            Text(text)
                .allowsTightening(true)
                .foregroundStyle(Color.appPrimaryText)

            Button(action: onDeleted) {
                Image(systemName: "xmark").foregroundStyle(Color.appBorder)
            }
            .buttonStyle(.plain)
        }
        .lineLimit(1)
        .truncationMode(.tail)
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .background(Color.appSurfaceDeep)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.appBorder, lineWidth: 2)
        )
        .cornerRadius(20)
    }
}

#Preview {
    SearchBadge(id: "assadsd", text: "괜찮아 괜찮43괜찮아 괜찮43괜찮아 괜찮43 ㅁㄴㅇㅁㄴㅇㄹㅇㄴㄹㅁㄴㅇㄹㅇㄴㅇㄹ", onTapped: {}, onDeleted: {})
}
