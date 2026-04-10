import SwiftUI

struct MainLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(LocalizedStringKey(text))
            .foregroundStyle(Color.appSecondaryText)
            .font(.system(size: 18, weight: .medium))
    }
}

#Preview("MainLabel") {
    VStack(alignment: .leading, spacing: 8) {
        MainLabel("메모")
        MainLabel("상태")
    }
    .padding()
    .background(Color.black)
}
