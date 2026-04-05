import SwiftUI

struct BookGridItem: View {
    let title: String
    let author: String
    let imageURL: String?
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
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
                .background(Color.appSurfaceDeeper)
                .overlay {
                    if isDisabled {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.28))
                    }
                }

                Image(systemName: checkboxImageName)
                    .font(.system(size: checkboxFontSize, weight: .semibold))
                    .foregroundStyle(checkboxForegroundColor)
                    .frame(width: 20, height: 20)
                    .background(checkboxBackground)
                    .padding(8)
            }

            Text(title)
                .font(.subheadline.bold())
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(isDisabled ? Color.gray.opacity(0.95) : Color.appPrimaryText)

            Text(author)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(isDisabled ? Color.gray.opacity(0.75) : .secondary)
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 160)
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .saturation(isDisabled ? 0 : 1)
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(borderColor, lineWidth: borderLineWidth)
        }
        .contentShape(Rectangle())
        .opacity(isDisabled ? 0.55 : 1.0)
        .onTapGesture {
            guard !isDisabled else { return }
            onTap()
        }
    }

    private var checkboxImageName: String {
        if isDisabled {
            return isSelected ? "checkmark.square.fill" : "square"
        }
        return isSelected ? "checkmark" : "square"
    }

    private var checkboxFontSize: CGFloat {
        isSelected ? 12 : 22
    }

    private var checkboxForegroundColor: Color {
        if isDisabled {
            return isSelected ? .white.opacity(0.85) : .gray
        }
        return isSelected ? .white : .gray
    }

    @ViewBuilder
    private var checkboxBackground: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 3)
                .fill(isDisabled ? Color.gray.opacity(0.7) : .blue)
        }
    }

    private var cardBackgroundColor: Color {
        isDisabled ? Color.appSurfaceDeeper : Color.appSurfaceDeep
    }

    private var borderColor: Color {
        if isDisabled {
            return Color.gray.opacity(0.35)
        }
        return isSelected ? .blue : .clear
    }

    private var borderLineWidth: CGFloat {
        (isSelected || isDisabled) ? 2 : 0
    }

    private var placeholder: some View {
        ZStack {
            Color.appSurface
            Image(systemName: "book.closed")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        BookGridItem(
            title: "샘플 책 제목",
            author: "샘플 작가",
            imageURL: nil,
            isSelected: true,
            isDisabled: false,
            onTap: {}
        )

        BookGridItem(
            title: "비활성화된 책 제목",
            author: "비활성 작가",
            imageURL: nil,
            isSelected: false,
            isDisabled: true,
            onTap: {}
        )

        BookGridItem(
            title: "선택됐지만 비활성화",
            author: "회색 처리",
            imageURL: nil,
            isSelected: true,
            isDisabled: true,
            onTap: {}
        )
    }
    .padding()
    .background(Color.black)
}
