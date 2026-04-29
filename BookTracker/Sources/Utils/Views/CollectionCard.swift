//
//  CollectionCard.swift
//  BookTracker
//
//  Created by 배성연 on 2/11/26.
//

import Kingfisher
import SwiftUI

struct CollectionCard: View {
    let summary: UserCollectionSummary
    let onTap: () -> Void
    let onDelete: () -> Void

    init(
        summary: UserCollectionSummary,
        onTap: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.summary = summary
        self.onTap = onTap
        self.onDelete = onDelete
    }

    private var titleText: String {
        summary.displayName
    }

    private var previewBooks: [CollectionPreviewBook] {
        Array(summary.previewBooks.prefix(2))
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                previewArea

                Text(titleText)
                    .font(.headline)
                    .foregroundStyle(Color.appPrimaryText)
                    .lineLimit(1)
                    .padding(.top, 8)
            }
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .contextMenu {
            if summary.type == .custom {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("delete", systemImage: "trash")
                }
            }
        }
    }

    @ViewBuilder
    private var previewArea: some View {
        switch previewBooks.count {
        case 0:
            emptyPreview
        case 1:
            HStack(spacing: 6) {
                remoteBookImage(urlString: previewBooks[0].thumbnail)
                placeholderSlot
            }
        default:
            HStack(spacing: 6) {
                remoteBookImage(urlString: previewBooks[0].thumbnail)
                remoteBookImage(urlString: previewBooks[1].thumbnail)
            }
        }
    }

    private var emptyPreview: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.appPlaceholder)
            .frame(height: 80)
            .overlay {
                VStack(spacing: 6) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.appSecondaryText)

                    Text("no_books_yet")
                        .font(.caption)
                        .foregroundStyle(Color.appSecondaryText)
                }
            }
    }

    private var placeholderSlot: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Color.appPlaceholder)
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .overlay {
                Image(systemName: "book.closed")
                    .foregroundStyle(Color.appSecondaryText)
            }
    }

    @ViewBuilder
    private func remoteBookImage(urlString: String?) -> some View {
        if let urlString, let url = URL(string: urlString) {
            KFImage(url)
                .placeholder {
                    imagePlaceholder(systemName: "book.closed")
                }
                .retry(maxCount: 2, interval: .seconds(1))
                .fade(duration: 0.2)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        } else {
            imagePlaceholder(systemName: "book.closed")
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
    }

    private func imagePlaceholder(systemName: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.appPlaceholder)

            Image(systemName: systemName)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.appSecondaryText)
                .imageScale(.large)
        }
    }
}

#Preview("Empty Collection") {
    CollectionCard(
        summary: .init(
            id: UUID(),
            userId: UUID(),
            name: "구매한 책",
            type: .custom,
            createdAt: Date(),
            description: "아직 책이 없는 컬렉션",
            previewBooks: []
        ),
        onTap: {},
        onDelete: {}
    )
    .frame(width: 180)
    .padding()
    .background(Color.black)
}

#Preview("One Book") {
    CollectionCard(
        summary: .init(
            id: UUID(),
            userId: UUID(),
            name: "읽는 중",
            type: .custom,
            createdAt: Date(),
            description: "한 권만 있는 컬렉션",
            previewBooks: [
                .init(
                    id: UUID(),
                    title: "Atomic Habits",
                    thumbnail: "https://images.unsplash.com/photo-1544947950-fa07a98d237f?q=80&w=600&auto=format&fit=crop"
                )
            ]
        ),
        onTap: {},
        onDelete: {}
    )
    .frame(width: 180)
    .padding()
    .background(Color.black)
}

#Preview("Two Books") {
    CollectionCard(
        summary: .init(
            id: UUID(),
            userId: UUID(),
            name: "추가한 책",
            type: .custom,
            createdAt: Date(),
            description: "대표 책 2권",
            previewBooks: [
                .init(
                    id: UUID(),
                    title: "Book A",
                    thumbnail: "https://images.unsplash.com/photo-1512820790803-83ca734da794?q=80&w=600&auto=format&fit=crop"
                ),
                .init(
                    id: UUID(),
                    title: "Book B",
                    thumbnail: "https://images.unsplash.com/photo-1516979187457-637abb4f9353?q=80&w=600&auto=format&fit=crop"
                )
            ]
        ),
        onTap: {},
        onDelete: {}
    )
    .frame(width: 180)
    .padding()
    .background(Color.black)
}

#Preview("Multiple Cards") {
    HStack(spacing: 16) {
        CollectionCard(
            summary: .init(
                id: UUID(),
                userId: UUID(),
                name: "빈 컬렉션",
                type: .custom,
                createdAt: Date(),
                description: nil,
                previewBooks: []
            ),
            onTap: {},
            onDelete: {}
        )
        .frame(width: 180)

        CollectionCard(
            summary: .init(
                id: UUID(),
                userId: UUID(),
                name: "보관함",
                type: .purchase,
                createdAt: Date(),
                description: nil,
                previewBooks: [
                    .init(
                        id: UUID(),
                        title: "Book A",
                        thumbnail: "https://images.unsplash.com/photo-1512820790803-83ca734da794?q=80&w=600&auto=format&fit=crop"
                    ),
                    .init(
                        id: UUID(),
                        title: "Book B",
                        thumbnail: "https://images.unsplash.com/photo-1544947950-fa07a98d237f?q=80&w=600&auto=format&fit=crop"
                    )
                ]
            ),
            onTap: {},
            onDelete: {}
        )
        .frame(width: 180)
    }
    .padding()
    .background(Color.black)
}
