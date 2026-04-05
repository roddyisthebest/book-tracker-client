import SwiftUI

struct FormTextField: View {
    let placeholder: String
    @Binding var text: String
    var height: CGFloat = 50
    var backgroundColor: Color = .appSurfaceDeep
    var autocapitalization: TextInputAutocapitalization? = .sentences
    var autocorrectionDisabled: Bool = false
    var keyboardType: UIKeyboardType? = nil

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundStyle(Color.appSecondaryText)
                    .padding(.horizontal, 16)
            }

            TextField("", text: $text)
                .foregroundStyle(Color.appPrimaryText)
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
