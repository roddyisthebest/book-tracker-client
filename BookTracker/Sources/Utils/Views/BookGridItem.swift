import SwiftUI

struct BookGridItem: View {
    let title: String
    let author: String
    let imageURL: String?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                // Image area
                Group {
                    if let imageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                Color.gray.opacity(0.2)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                placeholder
                            @unknown default:
                                placeholder
                            }
                        }
                    } else {
                        placeholder
                    }
                }
                .frame(height: 100)
                .frame(maxWidth: .infinity)
                .clipped()
                .background(Color(hex: "#202026"))

                // Checkbox indicator
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
                    ).padding(8)
            }

            Text(title)
                .font(.subheadline).bold()
                .lineLimit(1)
                .foregroundStyle(.white)
                .truncationMode(.tail)

            Text(author)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 160)
        .background(Color(hex: "#17171C"))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue, lineWidth: 2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    private var placeholder: some View {
        ZStack {
            Color(hex: "#2C2C35")
            Image(systemName: "book.closed")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    BookGridItem(
        title: "샘플 책 제목",
        author: "샘플 작가",
        imageURL: nil,
        isSelected: true,
        onTap: {}
    )
    .padding()
    .background(Color.black)
}
