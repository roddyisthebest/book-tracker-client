import SwiftUI

struct FormTextEditor: View {
    let placeholder: String
    @Binding var text: String
    var height: CGFloat = 160
    var backgroundColor: Color = .appSurfaceDeep
    var autocapitalization: TextInputAutocapitalization? = .sentences
    var autocorrectionDisabled: Bool = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundStyle(Color.appSecondaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
            }

            TextEditor(text: $text)
                .foregroundStyle(Color.appPrimaryText)
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
