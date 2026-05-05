//
//  DoneBookThumbnailsGrid.swift
//  BookTracker
//
//  Created by 배성연 on 4/4/26.
//
import Kingfisher
import SwiftUI

struct DoneBookThumbnailsGrid: View {
    static let maxVisible = 2

    let items: [BookCalendarSummary]
    let totalCount: Int?

    init(items: [BookCalendarSummary], totalCount: Int? = nil) {
        self.items = items
        self.totalCount = totalCount
    }

    private var displayCount: Int {
        totalCount ?? items.count
    }

    private var overflowCount: Int {
        displayCount - Self.maxVisible
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            thumbnailLayout
            countBadge
        }
    }

    @ViewBuilder
    private var thumbnailLayout: some View {
        switch items.count {
        case 0:
            Color.clear
        case 1:
            ThumbnailCell(item: items[0])
        default:
            HStack(spacing: 1) {
                ForEach(Array(items.prefix(Self.maxVisible).enumerated()), id: \.offset) { _, item in
                    ThumbnailCell(item: item)
                }
            }
        }
    }

    private var countBadge: some View {
        Text(overflowCount > 0 ? "+\(overflowCount)" : "\(displayCount)")
            .font(.system(size: 9, weight: .heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(Color.black)
                    .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 0.5))
            )
            .clipShape(Capsule())
            .padding(2)
    }
}

private struct ThumbnailCell: View {
    let item: BookCalendarSummary

    var body: some View {
        Color.clear
            .overlay {
                if let urlString = item.imageUrl, let url = URL(string: urlString) {
                    KFImage(url)
                        .placeholder {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(hex: "#2C2C35", default: .secondary))
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "#2C2C35", default: .secondary))
                        Image(systemName: "book.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 2))
    }
}
