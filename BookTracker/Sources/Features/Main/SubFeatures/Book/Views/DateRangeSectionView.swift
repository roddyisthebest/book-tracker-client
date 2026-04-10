import ComposableArchitecture
import SwiftUI

struct DateRangeSectionView: View {
    @Bindable var store: StoreOf<BookFormFeature>

    var body: some View {
        VStack(alignment: .leading) {
            VStack {
                DatePicker("start_date", selection: $store.startedAt, displayedComponents: [.date])
                    .padding(.horizontal)
                    .padding(.top, 10)
                Divider().background(Color.appSeparator).padding(.leading)
                DatePicker("end_date", selection: $store.endedAt, displayedComponents: [.date])
                    .padding(.horizontal)
                    .padding(.bottom, 12.5)
                    .padding(.top, 2.5)
            }
            .background(Color.appSurfaceDeep)
            .cornerRadius(15)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}
