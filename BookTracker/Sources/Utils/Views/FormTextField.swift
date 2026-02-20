import SwiftUI

struct FormTextField: View {
    let placeholder: String
    @Binding var text: String
    var height: CGFloat = 50
    var backgroundColor: Color = .init(hex: "#17171C", default: .accentColor)
    var autocapitalization: TextInputAutocapitalization? = .sentences
    var autocorrectionDisabled: Bool = false
    var keyboardType: UIKeyboardType? = nil

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.horizontal, 16)
            }

            TextField("", text: $text)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(autocorrectionDisabled)
                .keyboardType(keyboardType ?? .default)
        }
        .frame(height: height)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
}
