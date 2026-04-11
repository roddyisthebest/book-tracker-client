import ComposableArchitecture
import SwiftUI

struct TypeSectionView: View {
    @Bindable var store: StoreOf<BookFormFeature>

    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .leading) {
                Picker("", selection: $store.type) {
                    ForEach(BookType.allCases) { t in
                        Text(t.title).tag(Optional(t))
                    }
                }
                .padding(.trailing, 15)
                .padding(.leading, 5)
                .padding(.vertical, 13)
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.appSurfaceDeep)
                .cornerRadius(15)
            }
            .contentShape(Rectangle())
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

#Preview {
    TypeSectionView(
        store: Store(
            initialState: BookFormFeature.State(
                externalId: "preview",
                bookId: nil
            )
        ) {
            BookFormFeature()
        }
    )
    .padding()
}
