import SwiftUI

struct SelectBookRow: View {
    let title: String
    let author: String
    let publisher: String
    let isbn: String
    let thumbnail: String?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 10) {
                VStack {
                    Image(systemName: isSelected ? "checkmark" : "square")
                        .font(.system(size: isSelected ? 12 : 22, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : .gray)
                        .frame(width: 20, height: 20)
                        .background(
                            Group {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(.blue)
                                }
                            }
                        )
                }

                VStack(alignment: .leading) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundStyle(.white)

                    HStack(alignment: .top, spacing: 10) {
                        thumbnailView

                        VStack(alignment: .leading, spacing: 4) {
                            if !author.isEmpty {
                                Text(author)
                                    .foregroundStyle(.white.opacity(0.7))
                                    .font(.system(size: 14, weight: .semibold))
                                    .lineLimit(2)
                                    .truncationMode(.tail)
                            }

                            if !publisher.isEmpty {
                                Text(publisher)
                                    .foregroundStyle(.white.opacity(0.6))
                                    .font(.system(size: 11, weight: .semibold))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }

                            if !isbn.isEmpty {
                                HStack {
                                    Image(systemName: "barcode")
                                        .font(.system(size: 14, weight: .semibold))

                                    Text("ISBN \(isbn)")
                                        .font(.caption2)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .foregroundStyle(.white)
                                }
                                .padding(6)
                                .background(Color(hex: "#2A2A33", default: .gray))
                                .cornerRadius(4)
                                .padding(.top, 2)
                            }
                        }

                        Spacer()
                    }
                }
            }
            .padding()
        }
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.blue, lineWidth: 2)
            }
        }
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnail,
           let url = URL(string: thumbnail)
        {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    thumbnailPlaceholder

                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()

                case .failure:
                    thumbnailPlaceholder

                @unknown default:
                    thumbnailPlaceholder
                }
            }
            .frame(width: 80, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            thumbnailPlaceholder
        }
    }

    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color(hex: "#2A2A33", default: .gray))
            .frame(width: 80, height: 100)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            )
    }
}

#Preview("SelectBookRow Samples") {
    VStack(spacing: 16) {
        SelectBookRow(
            title: "스위프트UI와 TCA 제대로 배우기",
            author: "홍길동",
            publisher: "예제출판사",
            isbn: "9781234567890",
            thumbnail: nil,
            isSelected: false,
            onTap: {}
        )
        .background(Color(hex: "#17171C"))
        .cornerRadius(10)

        SelectBookRow(
            title: "iOS 아키텍처 실무 가이드",
            author: "이몽룡",
            publisher: "실무출판",
            isbn: "9780987654321",
            thumbnail: "https://picsum.photos/80/100",
            isSelected: true,
            onTap: {}
        )
        .background(Color(hex: "#17171C"))
        .cornerRadius(10)
    }
    .padding()
    .background(Color(hex: "#2C2C35", default: .black))
}
