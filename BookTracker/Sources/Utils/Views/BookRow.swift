import SwiftUI

struct BookRow: View {
    let book: Book
    let onTap: () -> Void
    let onDelete: () -> Void

    @ViewBuilder
    private var AddedView: some View {
        switch book.stereo {
        case .done:
            HStack(spacing: 5) {
                Image(systemName: "star.fill")
                Image(systemName: "star.leadinghalf.filled")
                Image(systemName: "star")
                Image(systemName: "star")
                Image(systemName: "star")
            }.padding(.vertical, 5).foregroundStyle(.yellow)
        case .reading:
            let progress = 0.6
            VStack(alignment: .leading, spacing: 5) {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(hex: "#2A2A33", default: .gray))
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
                Text("100% (123p/526p)").foregroundStyle(Color(hex: "#9B9BA1", default: .gray)).font(.caption2)
            }.padding(.vertical, 7.5)
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
                        Text(book.author).foregroundStyle(.white.opacity(0.7)).font(.system(size: 14, weight: .semibold))
                            .lineLimit(2)
                            .truncationMode(.tail)
                        Text(book.publisher).foregroundStyle(.white.opacity(0.6)).font(.system(size: 11, weight: .semibold))
                            .lineLimit(1)
                            .truncationMode(.tail)

                        AddedView
                    }
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(hex: "#17171C"))
        .cornerRadius(10)
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("삭제", systemImage: "trash")
            }

            // 필요하면 다른 메뉴도 추가 가능 (예: 공유)
            Button {
                // 공유 등 다른 액션
            } label: {
                Label("공유", systemImage: "square.and.arrow.up")
            }
        }
    }
}

#Preview("SelectBookRow Samples") {
    VStack(spacing: 16) {
        BookRow(
            book: Book(id: UUID(1), title: "스위프트와 제대로 배우기", author: "피자", publisher: "ㅁㄴㅇㅇ", imageUrl: nil, isbn: "1231232322212", stereo: .done),
            onTap: {},
            onDelete: {}
        )

        BookRow(
            book: Book(id: UUID(1), title: "스위프트와 제대로 배우기", author: "피자", publisher: "ㅁㄴㅇㅇ", imageUrl: nil, isbn: "1231232322212", stereo: .reading),
            onTap: {},
            onDelete: {}
        )
    }
    .padding()
    .background(Color(hex: "#2C2C35", default: .black))
}
