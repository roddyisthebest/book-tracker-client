import SwiftUI
import Kingfisher

struct BookRow: View {
    let book: Book
    let onTap: () -> Void
    let onDelete: () -> Void

    @ViewBuilder
    private var AddedView: some View {
        switch book.status {
        case .done:
            let rating = min(max(book.score ?? 0, 0), 5)
            HStack(spacing: 5) {
                ForEach(0 ..< 5, id: \.self) { i in
                    let diff = rating - Double(i)
                    Image(systemName: diff >= 1 ? "star.fill" : (diff >= 0.5 ? "star.leadinghalf.filled" : "star"))
                }
            }
            .padding(.vertical, 5)
            .foregroundStyle(.yellow)
        case .reading:
            if let read = book.readCount, let total = book.pageCount, total > 0 {
                let progress = min(max(Double(read) / Double(total), 0), 1)
                VStack(alignment: .leading, spacing: 5) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.appSurface)
                            .frame(height: 5)

                        GeometryReader { proxy in
                            let fullWidth = proxy.size.width
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.blue.opacity(0.6))
                                .frame(width: fullWidth * progress, height: 5)
                        }
                    }
                    .frame(height: 5)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    Text("\(Int(progress * 100))% (\(read)p/\(total)p)")
                        .foregroundStyle(Color.appSecondaryText)
                        .font(.caption2)
                }
                .padding(.vertical, 7.5)
            } else {
                EmptyView()
            }
        default:
            EmptyView()
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading) {
                Text(book.title)
                    .font(.system(size: 18, weight: .bold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(Color.appPrimaryText)

                HStack(alignment: .top, spacing: 10) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.appSurface)
                        .frame(width: 80, height: 100)
                        .overlay {
                            if let urlString = book.imageUrl, let url = URL(string: urlString) {
                                KFImage(url)
                                    .placeholder {
                                        ProgressView().tint(.secondary)
                                    }
                                    .retry(maxCount: 2, interval: .seconds(1))
                                    .fade(duration: 0.2)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Image(systemName: "photo")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.author).foregroundStyle(Color.appSecondaryText).font(.system(size: 14, weight: .semibold))
                            .lineLimit(2)
                            .truncationMode(.tail)
                        Text(book.publisher).foregroundStyle(Color.appSecondaryText.opacity(0.8)).font(.system(size: 11, weight: .semibold))
                            .lineLimit(1)
                            .truncationMode(.tail)

                        AddedView
                    }
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.appSurfaceDeep)
        .cornerRadius(10)
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("delete", systemImage: "trash")
            }

            // 필요하면 다른 메뉴도 추가 가능 (예: 공유)
            Button {
                // 공유 등 다른 액션
            } label: {
                Label("share", systemImage: "square.and.arrow.up")
            }
        }
    }
}

#Preview("SelectBookRow Samples") {
    VStack(spacing: 16) {
        BookRow(
            book: Book(
                id: UUID(),
                userId: UUID(),
                externalBookId: nil,
                title: "whatttup",
                author: "we up now",
                publisher: "pubbb",
                pageCount: 300,
                pageCountEditable: false,
                imageUrl: nil,
                isbn: "123232",
                status: .done,
                type: .ebook,
                startedAt: Date(),
                readCount: nil,
                memo: nil,
                endedAt: nil,
                score: 0.5,
                review: nil,
                droppedReason: nil
            ),
            onTap: {},
            onDelete: {}
        )

        BookRow(
            book: Book(
                id: UUID(),
                userId: UUID(),
                externalBookId: nil,
                title: "whatttup",
                author: "we up now",
                publisher: "pubbb",
                pageCount: 300,
                pageCountEditable: false,
                imageUrl: nil,
                isbn: "123232",
                status: .reading,
                type: .ebook,
                startedAt: Date(),
                readCount: 0,
                memo: nil,
                endedAt: nil,
                score: 0.5,
                review: nil,
                droppedReason: nil,

            ),
            onTap: {},
            onDelete: {}
        )

        BookRow(
            book: Book.make(),
            onTap: {},
            onDelete: {}
        )
    }
    .padding()
    .background(Color(hex: "#2C2C35", default: .black))
}
