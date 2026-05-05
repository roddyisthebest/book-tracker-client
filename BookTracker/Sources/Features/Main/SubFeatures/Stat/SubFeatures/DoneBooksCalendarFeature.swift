import ComposableArchitecture
import Foundation

@Reducer
struct DoneBooksCalendarFeature {
    @Dependency(\.date) var date
    @Dependency(\.bookService) var bookService

    @ObservableState
    struct State: Equatable {
        var date: Date = .init()
        var loadingState: LoadingState = .idle
        var thumbnailsByDate: [Date: BookCalendarDay]?

        @Presents var alert: AlertState<Action.Alert>?
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case loadData
        case loadDataResponse(Result<[Date: BookCalendarDay], AppError>)
        case saveSuccess
        case saveFailed
        case alert(PresentationAction<Alert>)
        enum Alert: Equatable {}
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
                state.loadingState = .loading
                state.thumbnailsByDate = nil
                let calendar = Calendar(identifier: .gregorian)
                let comps = calendar.dateComponents([.year, .month], from: state.date)
                let year = comps.year ?? calendar.component(.year, from: date.now)
                let month = comps.month ?? calendar.component(.month, from: date.now)
                return .run { send in
                    let result = await bookService.calendarByMonth(year, month, .done, nil)
                    await send(.loadDataResponse(result))
                }
            case .loadDataResponse(let result):
                switch result {
                case .success(let dict):
                    state.loadingState = .loaded
                    state.thumbnailsByDate = dict
                case .failure:
                    state.loadingState = .error
                }
                return .none
            case .saveSuccess:
                state.alert = .saveSuccess()
                return .none
            case .saveFailed:
                state.alert = .saveFailed()
                return .none
            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

extension AlertState where Action == DoneBooksCalendarFeature.Action.Alert {
    static func saveSuccess() -> Self {
        Self {
            TextState("save_success")
        } actions: {
            ButtonState(role: .cancel) { TextState("confirm") }
        } message: {
            TextState("save_success_message")
        }
    }

    static func saveFailed() -> Self {
        Self {
            TextState("save_failed")
        } actions: {
            ButtonState(role: .cancel) { TextState("confirm") }
        } message: {
            TextState("save_failed_message")
        }
    }
}
