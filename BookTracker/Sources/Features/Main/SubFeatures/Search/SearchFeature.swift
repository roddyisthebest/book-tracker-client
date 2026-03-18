//
//  SearchFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/17/26.
//

import ComposableArchitecture

@Reducer
struct SearchFeature {
    @ObservableState
    struct State: Equatable {
        var query: String = ""
        var destination: Destination.State = .suggestions(SearchSuggestionsFeature.State())

        @Presents var detailSheet: ExternalBookDetailFeature.State?
    }

    enum Action: Equatable, BindableAction {
        case detailSheet(PresentationAction<ExternalBookDetailFeature.Action>)
        case destination(Destination.Action)
        case queryResetButtonTapped
        case binding(BindingAction<State>)
        /// 내부 전용: 자식 검색 이펙트를 취소한 다음에 suggestions로 안전하게 전환할 때 사용.
        /// setKeyword("")로 취소를 유도한 뒤, 순서를 보장하기 위해 .concatenate 다음 단계에서 이 액션을 보냅니다.
        case _setSuggestions
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
                    // When query becomes empty, cancel any in-flight search in the results child first,
                    // then switch to suggestions to avoid "child action when state is different case" warnings.
                    switch state.destination {
                    case .results:
                        // 1) 자식 검색 취소 → 2) suggestions 전환 (.concatenate로 순서 보장)
                        return .concatenate(
                            .send(.destination(.results(.cancelSearch))),
                            .send(._setSuggestions)
                        )
                    case .suggestions:
                        state.destination = .suggestions(SearchSuggestionsFeature.State())
                        return .none
                    }
                } else {
                    // Ensure we are on the results screen, creating it if needed
                    if case .results = state.destination {
                        // already on results, keep it
                    } else {
                        state.destination = .results(SearchResultFeature.State(keyword: trimmed))
                    }
                    // Pass keyword down to child (child debounces + searches)
                    return .send(.destination(.results(.setKeyword(trimmed))))
                }

            case .queryResetButtonTapped:
                state.query = ""
                // If currently showing results, cancel child's search first, then switch to suggestions
                switch state.destination {
                case .results:
                    // 1) 자식 검색 취소 → 2) suggestions 전환 (.concatenate로 순서 보장)
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

                state.destination = .results(SearchResultFeature.State(keyword: keyword))
                return .send(.destination(.results(.setKeyword(keyword))))

            case .detailSheet(.presented(.destination(.presented(.formBook(.delegate(.confirmCreation(let book))))))):
                print(book)
                state.detailSheet = nil
                return .none

            case .detailSheet:
                return .none

            case .destination(.results(.delegate(.tapBook(let id)))):
                state.detailSheet = ExternalBookDetailFeature.State(id: id)
                return .none

            case ._setSuggestions:
                state.destination = .suggestions(SearchSuggestionsFeature.State())
                return .none

            case .destination:
                return .none

            case .binding:
                return .none
            }
        }

        .ifLet(\.$detailSheet, action: \.detailSheet) { ExternalBookDetailFeature() }
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
