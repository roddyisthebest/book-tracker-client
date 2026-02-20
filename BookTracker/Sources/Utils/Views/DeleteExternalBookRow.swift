import SwiftUI

struct DeleteExternalBookRow: View {
    let title: String
    let author: String
    let publisher: String
    let isbn: String
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 10) {
                // (선택 아이콘 없음) - SelectBookRow와 동일 레이아웃에서 체크박스만 제거
                VStack(alignment: .leading) {
                    Text(title)
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
                            Text(author)
                                .foregroundStyle(.white.opacity(0.7))
                                .font(.system(size: 14, weight: .semibold))
                                .lineLimit(2)
                                .truncationMode(.tail)
                            Text(publisher)
                                .foregroundStyle(.white.opacity(0.6))
                                .font(.system(size: 11, weight: .semibold))
                                .lineLimit(1)
                                .truncationMode(.tail)

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
                        Spacer()
                    }
                }
            }
            .padding()
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 10))
        // 오른쪽 상단 X 버튼
        .overlay(alignment: .topTrailing) {
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.red)
                    .padding(16)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview("DeleteBookRow Samples") {
    VStack(spacing: 16) {
        DeleteExternalBookRow(
            title: "스위프트UI와 TCA 제대로 배우기",
            author: "홍길동",
            publisher: "예제출판사",
            isbn: "9781234567890",
            onTap: {},
            onDelete: {}
        )
        .background(Color(hex: "#17171C"))
        .cornerRadius(10)

        DeleteExternalBookRow(
            title: "iOS 아키텍처 실무 가이드",
            author: "이몽룡",
            publisher: "실무출판",
            isbn: "9780987654321",
            onTap: {},
            onDelete: {}
        )
        .background(Color(hex: "#17171C"))
        .cornerRadius(10)
    }
    .padding()
    .background(Color(hex: "#2C2C35", default: .black))
}
