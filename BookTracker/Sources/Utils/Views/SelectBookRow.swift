import SwiftUI

struct SelectBookRow: View {
    let title: String
    let author: String
    let publisher: String
    let isbn: String
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
                            Text(author).foregroundStyle(.white.opacity(0.7)).font(.system(size: 14, weight: .semibold))
                                .lineLimit(2)
                                .truncationMode(.tail)
                            Text(publisher).foregroundStyle(.white.opacity(0.6)).font(.system(size: 11, weight: .semibold))
                                .lineLimit(1)
                                .truncationMode(.tail)

                            HStack {
                                Image(systemName: "barcode")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("ISBN \(isbn)").font(.caption2).lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            .padding(6)
                            .background(Color(hex: "#2A2A33", default: .gray)).cornerRadius(4)
                            .padding(.top, 2)
                        }
                        Spacer()
                    }
                }
            }
        }
    }
}
