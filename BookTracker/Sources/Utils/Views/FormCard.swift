import SwiftUI

struct FormCard<Content: View>: View {
    var labelText: String = ""
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            FormLabel(text: labelText)
            content()
                .padding(0)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}
