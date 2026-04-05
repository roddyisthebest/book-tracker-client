import ComposableArchitecture
import Foundation

@Reducer
struct DoneBooksCalendarFeature {
    @Dependency(\.bookService) var bookService

    @ObservableState
    struct State: Equatable {
        var date: Date = .init()
        var isLoading: Bool = false
        var isError: Bool = false
        var thumbnailsByDate: [Date: [BookCalendarSummary]]?
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case loadData
        case loadDataResponse(Result<[Date: [BookCalendarSummary]], AppError>)
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding(\.date):
                return .send(.loadData)
            case .binding:
                return .none
            case .onAppear:
                return .send(.loadData)
            case .loadData:
                state.isLoading = true
                state.isError = false
                state.thumbnailsByDate = nil
                let calendar = Calendar(identifier: .gregorian)
                let comps = calendar.dateComponents([.year, .month], from: state.date)
                let year = comps.year ?? calendar.component(.year, from: Date())
                let month = comps.month ?? calendar.component(.month, from: Date())
                return .run { send in
                    let result = await bookService.calendarByMonth(year, month, .done, nil)
                    await send(.loadDataResponse(result))
                }
            case .loadDataResponse(let result):
                state.isLoading = false
                switch result {
                case .success(let dict):
                    state.thumbnailsByDate = dict
                case .failure:
                    state.isError = true
                }
                return .none
            }
        }
    }
}
