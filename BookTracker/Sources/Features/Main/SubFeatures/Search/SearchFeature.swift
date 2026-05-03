//
//  SearchFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/17/26.
//

import ComposableArchitecture

@Reducer
struct SearchFeature {
    @Dependency(\.localCustomBookService) var localCustomBookService
    @Shared(.userProfile) var profile: MyProfile?

    @ObservableState
    struct State: Equatable {
        var query: String = ""
        var destination: Destination.State = .suggestions(SearchSuggestionsFeature.State())

        @Presents var detailSheet: ExternalBookDetailFeature.State?
        @Presents var customBookForm: CustomBookFormFeature.State?
        @Presents var customBookList: CustomBookListFeature.State?
    }

    enum Action: Equatable, BindableAction {
        case detailSheet(PresentationAction<ExternalBookDetailFeature.Action>)
        case customBookForm(PresentationAction<CustomBookFormFeature.Action>)
        case customBookList(PresentationAction<CustomBookListFeature.Action>)
        case destination(Destination.Action)
        case queryResetButtonTapped
        case binding(BindingAction<State>)
        /// 내부 전용: 자식 이펙트를 취소한 다음에 안전하게 전환할 때 사용.
        /// 취소를 유도한 뒤, 순서를 보장하기 위해 .concatenate 다음 단계에서 이 액션을 보냅니다.
        case _setSuggestions
        case _setResults(String)
    }

    var body: some ReducerOf<Self> {
        BindingReducer()

        // MARK: - Cancellation-first transition pattern

        /*
         TCA 경고(자식 액션이 도착했는데 상태 케이스가 다름)를 피하기 위해,
         .results에서 .suggestions로 전환하기 전에 먼저 자식의 검색 이펙트를 취소합니다.

         구현 방법:
         1) .destination(.results(.setKeyword("")))를 먼저 보내 자식이 .cancel(id: CancelID.search)를 반환하도록 유도
         2) 이어서 내부 액션 ._setSuggestions를 보내 케이스를 .suggestions로 전환
         3) 두 액션은 .concatenate로 순서를 보장

         참고: SearchResultFeature.setKeyword는 빈 문자열일 때 .cancel(id: CancelID.search)를 반환하고,
         검색 시작 이펙트는 .cancellable(id: CancelID.search, cancelInFlight: true)로 묶여 있습니다.
         */
        Scope(state: \.destination, action: \.destination) {
            Destination()
        }
        Reduce { state, action in
            switch action {
            case .binding(\.query):
                let trimmed = state.query.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    switch state.destination {
                    case .results:
                        return .concatenate(
                            .send(.destination(.results(.cancelSearch))),
                            .send(._setSuggestions)
                        )
                    case .suggestions:
                        return .none
                    }
                } else {
                    if case .results = state.destination {
                        return .send(.destination(.results(.setKeyword(trimmed))))
                    } else {
                        return .concatenate(
                            .send(.destination(.suggestions(.cancelLoading))),
                            .send(._setResults(trimmed))
                        )
                    }
                }

            case .queryResetButtonTapped:
                state.query = ""
                switch state.destination {
                case .results:
                    return .concatenate(
                        .send(.destination(.results(.cancelSearch))),
                        .send(._setSuggestions)
                    )
                case .suggestions:
                    state.destination = .suggestions(SearchSuggestionsFeature.State())
                    return .none
                }

            case .destination(.suggestions(.delegate(.setKeyword(let keyword)))):
                state.query = keyword
                return .concatenate(
                    .send(.destination(.suggestions(.cancelLoading))),
                    .send(._setResults(keyword))
                )

            case .destination(.suggestions(.delegate(.addCustomBook))):
                state.customBookForm = CustomBookFormFeature.State()
                return .none

            case .destination(.suggestions(.delegate(.openCustomBookList))):
                state.customBookList = CustomBookListFeature.State()
                return .none

            case .customBookList(.presented(.delegate(.openBook(let book)))):
                state.customBookList = nil
                state.detailSheet = ExternalBookDetailFeature.State(id: book.id, book: book)
                return .none

            case .customBookList:
                return .none

            case .customBookForm(.presented(.delegate(.didCreate(let externalBook)))):
                state.customBookForm = nil
                state.detailSheet = ExternalBookDetailFeature.State(id: externalBook.id, book: externalBook)
                let userId = profile?.id.uuidString ?? ""
                return .run { [localCustomBookService] _ in
                    _ = await localCustomBookService.save(externalBook, userId)
                }

            case .customBookForm:
                return .none

            case .detailSheet(.presented(.destination(.presented(.formBook(.delegate(.confirmCreation(let book))))))):
                let externalId = book.externalBookId
                state.detailSheet = nil
                if let externalId, externalId.hasPrefix("custom_") {
                    let userId = profile?.id.uuidString ?? ""
                    return .run { [localCustomBookService] _ in
                        _ = await localCustomBookService.remove(externalId, userId)
                    }
                }
                return .none

            case .detailSheet:
                return .none

            case .destination(.results(.delegate(.tapBook(let id)))):
                state.detailSheet = ExternalBookDetailFeature.State(id: id)
                return .none

            case ._setSuggestions:
                state.destination = .suggestions(SearchSuggestionsFeature.State())
                return .none

            case let ._setResults(keyword):
                state.destination = .results(SearchResultFeature.State(keyword: keyword))
                return .send(.destination(.results(.setKeyword(keyword))))

            case .destination:
                return .none

            case .binding:
                return .none
            }
        }

        .ifLet(\.$detailSheet, action: \.detailSheet) { ExternalBookDetailFeature() }
        .ifLet(\.$customBookForm, action: \.customBookForm) { CustomBookFormFeature() }
        .ifLet(\.$customBookList, action: \.customBookList) { CustomBookListFeature() }
    }
}

extension SearchFeature {
    @Reducer
    struct Destination {
        enum State: Equatable {
            case suggestions(SearchSuggestionsFeature.State)
            case results(SearchResultFeature.State)
        }

        enum Action: Equatable {
            case suggestions(SearchSuggestionsFeature.Action)
            case results(SearchResultFeature.Action)
        }

        var body: some ReducerOf<Self> {
            Scope(state: /State.suggestions, action: /Action.suggestions) {
                SearchSuggestionsFeature()
            }
            Scope(state: /State.results, action: /Action.results) {
                SearchResultFeature()
            }
        }
    }
}
