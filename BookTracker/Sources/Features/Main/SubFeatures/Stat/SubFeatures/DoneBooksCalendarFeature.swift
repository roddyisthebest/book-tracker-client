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

        @Presents var alert: AlertState<Action.Alert>?
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case loadData
        case loadDataResponse(Result<[Date: [BookCalendarSummary]], AppError>)
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
