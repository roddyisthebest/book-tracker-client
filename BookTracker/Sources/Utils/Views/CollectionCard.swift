//
//  CollectionCard.swift
//  BookTracker
//
//  Created by 배성연 on 2/11/26.
//

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
        if let name = summary.name, !name.isEmpty {
            return name
        }
        return String(localized: "unnamed_collection")
    }

    private var countText: String {
        String(format: String(localized: "book_count %@"), "\(summary.bookCount)")
    }

    private var previewBooks: [CollectionPreviewBook] {
        Array(summary.previewBooks.prefix(2))
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                previewArea

                VStack(alignment: .leading, spacing: 4) {
                    Text(titleText)
                        .font(.headline)
                        .foregroundStyle(Color.appPrimaryText)
                        .lineLimit(1)

                    Text(countText)
                        .font(.subheadline)
                        .foregroundStyle(Color.appSecondaryText)
                }
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
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("delete", systemImage: "trash")
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
        let url = urlString.flatMap(URL.init(string:))

        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                imagePlaceholder(systemName: "book.closed")
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                imagePlaceholder(systemName: "photo")
            @unknown default:
                imagePlaceholder(systemName: "photo")
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
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
            isDefault: false,
            createdAt: Date(),
            description: "아직 책이 없는 컬렉션",
            previewBooks: [],
            bookCount: 0
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
            isDefault: false,
            createdAt: Date(),
            description: "한 권만 있는 컬렉션",
            previewBooks: [
                .init(
                    id: UUID(),
                    title: "Atomic Habits",
                    thumbnail: "https://images.unsplash.com/photo-1544947950-fa07a98d237f?q=80&w=600&auto=format&fit=crop"
                )
            ],
            bookCount: 0
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
            isDefault: false,
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
            ],
            bookCount: 0
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
                isDefault: false,
                createdAt: Date(),
                description: nil,
                previewBooks: [],
                bookCount: 0
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
                isDefault: false,
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
                ],
                bookCount: 0
            ),
            onTap: {},
            onDelete: {}
        )
        .frame(width: 180)
    }
    .padding()
    .background(Color.black)
}
