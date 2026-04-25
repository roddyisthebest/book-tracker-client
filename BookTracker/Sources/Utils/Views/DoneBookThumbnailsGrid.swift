//
//  DoneBookThumbnailsGrid.swift
//  BookTracker
//
//  Created by 배성연 on 4/4/26.
//
import SwiftUI

struct DoneBookThumbnailsGrid: View {
    let items: [BookCalendarSummary] // up to 4

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 1), count: 2)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 1) {
            ForEach(Array(items.prefix(4)).indices, id: \.self) { idx in
                ThumbnailCell(item: items[idx])
            }
        }
    }
}

private struct ThumbnailCell: View {
    let item: BookCalendarSummary

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "#2C2C35", default: .secondary))
            // Image loading placeholder; replace with async image if available
            if let urlString = item.imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().tint(.white)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Image(systemName: "book.fill")
                            .foregroundStyle(.white.opacity(0.7))
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "book.fill")
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }
}
