import ComposableArchitecture
import SwiftUI

struct ReviewSectionView: View {
    @Bindable var store: StoreOf<BookFormFeature>

    var body: some View {
        VStack(alignment: .leading) {
            FormTextEditor(placeholder: "enter_review_placeholder", text: $store.reviewComment)
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}
