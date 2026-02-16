import ComposableArchitecture
import SwiftUI

struct StatusSectionView: View {
    @Bindable var store: StoreOf<BookFormFeature>

    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .leading) {
                Picker("", selection: $store.status) {
                    ForEach(BookStatus.allCases) { s in
                        Text(s.title).tag(s as BookStatus?)
                    }
                }
                .padding(.trailing, 15)
                .padding(.leading, 5)
                .padding(.vertical, 13)
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "#17171C", default: .accentColor))
                .cornerRadius(15)
            }
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}
