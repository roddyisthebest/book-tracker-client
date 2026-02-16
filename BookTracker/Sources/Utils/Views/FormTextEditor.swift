import SwiftUI

struct FormTextEditor: View {
    let placeholder: String
    @Binding var text: String
    var height: CGFloat = 160
    var backgroundColor: Color = .init(hex: "#17171C", default: .accentColor)
    var autocapitalization: TextInputAutocapitalization? = .sentences
    var autocorrectionDisabled: Bool = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
            }

            TextEditor(text: $text)
                .foregroundStyle(.white)
                .padding(12)
                .frame(height: height)
                .scrollIndicators(.visible)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(autocorrectionDisabled)
        }
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
}
