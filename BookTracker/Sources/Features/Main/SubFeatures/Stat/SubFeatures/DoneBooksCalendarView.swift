import ComposableArchitecture
import Kingfisher
import SwiftUI

struct DoneBooksCalendarView: View {
    @Bindable var store: StoreOf<DoneBooksCalendarFeature>
    @State private var imageSaver = ImageSaver()

    private var calendar: Calendar { Calendar.current }
    private var years: [Int] { Array(2000...2026) }
    
    private var yearBinding: Binding<Int> {
        Binding(
            get: { calendar.component(.year, from: store.date) },
            set: { year in
                var comps = calendar.dateComponents([.year, .month], from: store.date)
                comps.year = year
                comps.day = 1
                if let newDate = calendar.date(from: comps) {
                    $store.date.wrappedValue = newDate
                }
            }
        )
    }
    
    private var monthBinding: Binding<Int> {
        Binding(
            get: { calendar.component(.month, from: store.date) },
            set: { month in
                var comps = calendar.dateComponents([.year, .month], from: store.date)
                comps.month = month
                comps.day = 1
                if let newDate = calendar.date(from: comps) {
                    $store.date.wrappedValue = newDate
                }
            }
        )
    }
    
    @ViewBuilder
    private func dayContentView(for date: Date) -> some View {
        let cal = Calendar.current
        let key = cal.startOfDay(for: date)
        let day = store.thumbnailsByDate?[key] ?? .empty
        if day.books.isEmpty {
            Text("\(cal.component(.day, from: date))")
                .foregroundStyle(Color.appPrimaryText)
        } else {
            DoneBookThumbnailsGrid(items: Array(day.books.prefix(DoneBookThumbnailsGrid.maxVisible)), totalCount: day.totalCount)
        }
    }

    @ViewBuilder
    private func captureDayContentView(for date: Date) -> some View {
        let cal = Calendar.current
        let key = cal.startOfDay(for: date)
        let day = store.thumbnailsByDate?[key] ?? .empty
        if day.books.isEmpty {
            Text("\(cal.component(.day, from: date))")
                .foregroundStyle(Color.appPrimaryText)
        } else {
            CaptureThumbnailsGrid(items: Array(day.books.prefix(CaptureThumbnailsGrid.maxVisible)), totalCount: day.totalCount)
        }
    }

    private var captureView: some View {
        let year = calendar.component(.year, from: store.date)
        let month = calendar.component(.month, from: store.date)
        return VStack(spacing: 15) {
            HStack {
                Text("done_reading_calendar")
                    .font(.title3).fontWeight(.bold)
                    .foregroundStyle(Color.appPrimaryText)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 20)

            HStack {
                Text(String(format: String(localized: "month_format %@"), "\(month)"))
                    .font(.title2).fontWeight(.bold).foregroundStyle(Color.appPrimaryText)
                Text("\(year)" + String(localized: "year_suffix"))
                    .font(.title3).fontWeight(.semibold).foregroundStyle(Color.appSecondaryText)
                Spacer()
            }
            .padding(.horizontal)

            CustomCalendar(monthDate: .constant(store.date), selection: .constant(nil), showsHeader: false) { date in
                captureDayContentView(for: date)
            }
            .padding()
            .padding(.bottom, 20)
        }
        .frame(width: UIScreen.main.bounds.width)
        .background(Color.appBackground)
    }

    private func captureAndSave() {
        let renderer = ImageRenderer(content: captureView)
        renderer.scale = UIScreen.main.scale
        guard let image = renderer.uiImage else {
            store.send(.saveFailed)
            return
        }
        imageSaver.save(image) { success in
            DispatchQueue.main.async {
                if success {
                    store.send(.saveSuccess)
                } else {
                    store.send(.saveFailed)
                }
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                VStack(spacing: 20) {
                    HStack(alignment: .center, spacing: 10) {
                        Picker("year", selection: yearBinding) {
                            ForEach(years, id: \.self) { year in
                                (Text(year, format: .number.grouping(.never)) + Text("year_suffix"))
                                    .tag(year)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(3)
                        .tint(Color.appPrimaryText)
                        .background(Color.appSurface)
                        .cornerRadius(10)
                        
                        Picker("month", selection: monthBinding) {
                            ForEach(1...12, id: \.self) { month in
                                Text(String(format: String(localized: "month_format %@"), "\(month)")).tag(month)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(3)
                        .tint(Color.appPrimaryText)
                        .background(Color.appSurface)
                        .cornerRadius(10)
                    }
                    .padding()
                    
                    if store.loadingState == .loading && store.thumbnailsByDate == nil {
                        VStack(spacing: 8) {
                            ProgressView().tint(.white)
                            Text("loading")
                                .font(.footnote)
                                .foregroundStyle(Color.appSecondaryText)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .padding()
                    } else if store.loadingState == .error {
                        VStack(spacing: 8) {
                            Text("calendar_load_failed")
                                .font(.footnote)
                                .foregroundStyle(.red.opacity(0.85))
                            Button(action: { store.send(.loadData) }) {
                                Text("retry").font(.caption)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .padding()
                    } else {
                        CustomCalendar(monthDate: $store.date, selection: .constant(nil), showsHeader: false) { date in
                            dayContentView(for: date)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .refreshable { store.send(.loadData) }
        .background(Color.appBackground)
        .navigationTitle("done_reading_calendar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    captureAndSave()
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .disabled(store.loadingState == .loading || store.loadingState == .error || store.thumbnailsByDate == nil)
            }
        }
        .alert(store: store.scope(state: \.$alert, action: \.alert))
        .task { await store.send(.onAppear).finish() }
    }
}

private struct CaptureThumbnailsGrid: View {
    static let maxVisible = DoneBookThumbnailsGrid.maxVisible

    let items: [BookCalendarSummary]
    let totalCount: Int?

    init(items: [BookCalendarSummary], totalCount: Int? = nil) {
        self.items = items
        self.totalCount = totalCount
    }

    private var displayCount: Int {
        totalCount ?? items.count
    }

    private var overflowCount: Int {
        displayCount - Self.maxVisible
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            captureThumbnailLayout
            if overflowCount > 0 {
                Text("+\(overflowCount)")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(Color.black.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .padding(1)
            }
        }
    }

    @ViewBuilder
    private var captureThumbnailLayout: some View {
        switch items.count {
        case 0:
            Color.clear
        case 1:
            CaptureThumbnailCell(item: items[0])
        default:
            HStack(spacing: 1) {
                ForEach(Array(items.prefix(Self.maxVisible).enumerated()), id: \.offset) { _, item in
                    CaptureThumbnailCell(item: item)
                }
            }
        }
    }
}

private struct CaptureThumbnailCell: View {
    let item: BookCalendarSummary

    var body: some View {
        Color.clear
            .overlay {
                if let urlString = item.imageUrl,
                   let cached = ImageCache.default.retrieveImageInMemoryCache(forKey: urlString) {
                    Image(uiImage: cached)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "#2C2C35", default: .secondary))
                        Image(systemName: "book.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 2))
    }
}

#Preview {
    NavigationStack {
        DoneBooksCalendarView(store: Store(initialState: DoneBooksCalendarFeature.State(), reducer: { DoneBooksCalendarFeature() }))
    }
}
