import ComposableArchitecture
import SwiftUI

struct ReviewSectionView: View {
    @Bindable var store: StoreOf<BookFormFeature>

    var body: some View {
        VStack(alignment: .leading) {
            FormTextEditor(placeholder: "리뷰를 입력해주세요", text: $store.reviewComment)
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}
