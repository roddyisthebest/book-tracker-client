import SwiftUI

struct KeyValueRow<Key: View, Value: View>: View {
    @ViewBuilder let key: () -> Key
    @ViewBuilder let value: () -> Value

    init(
        @ViewBuilder key: @escaping () -> Key,
        @ViewBuilder value: @escaping () -> Value
    ) {
        self.key = key
        self.value = value
    }

    var body: some View {
        HStack(alignment: .top) {
            key()
            Spacer(minLength: 20)
            value()
        }
    }
}

struct KeyValueRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            KeyValueRow {
                MainLabel("메모")
            } value: {
                Text("안녕하세요 저는 미켈란젤로 입니다. 사람들은 이리 말하고 저리 말하지")
                    .foregroundStyle(.white.opacity(0.85))
                    .font(.system(size: 18, weight: .bold))
                    .multilineTextAlignment(.trailing)
            }
            .padding()
            .background(Color.black)
            .previewDisplayName("KeyValueRow - Basic Text")

            KeyValueRow {
                HStack(spacing: 6) {
                    Image(systemName: "book")
                    Text("상태")
                }
                .foregroundStyle(.white.opacity(0.75))
                .font(.system(size: 16, weight: .semibold))
            } value: {
                Text("읽는 중")
                    .foregroundStyle(.white)
                    .font(.system(size: 16, weight: .bold))
            }
            .padding()
            .background(Color(hex: "#17171C", default: .black))
            .previewDisplayName("KeyValueRow - With Icon Key")

            KeyValueRow {
                Text("정보")
                    .foregroundStyle(.white.opacity(0.7))
                    .font(.system(size: 16, weight: .medium))
            } value: {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("홍길동")
                        .font(.system(size: 16, weight: .bold))
                    Text("스위프트UI 개발자")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.white)
            }
            .padding()
            .background(Color(hex: "#2C2C35", default: .black))
            .previewDisplayName("KeyValueRow - Complex Value")

            // Additional varied examples

            KeyValueRow {
                Image(systemName: "phone.fill")
                    .foregroundColor(.green)
                Text("전화번호")
                    .font(.headline)
            } value: {
                Text("+82 10-1234-5678")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .previewDisplayName("KeyValueRow - Icon with Text")

            KeyValueRow {
                Text("프로필 사진")
                    .font(.body)
            } value: {
                Image("profile_placeholder")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            }
            .padding()
            .previewDisplayName("KeyValueRow - Image Value")
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .previewLayout(.sizeThatFits)
    }
}
