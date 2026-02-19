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
    }

    var body: some ReducerOf<Self> {
        BindingReducer()

        Scope(state: \.destination, action: \.destination) {
            Destination()
        }
        Reduce { state, action in
            switch action {
            case .binding(\.query):
                if state.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    state.destination = .suggestions(SearchSuggestionsFeature.State())
                } else {
                    state.destination = .results(SearchResultFeature.State(externalBooks: [
                        ExternalBook(id: "12", title: "dkfk"),
                        ExternalBook(id: "13", title: "good-day")

                    ], keyword: state.query))
                }
                return .none

            case .queryResetButtonTapped:
                state.query = ""
                state.destination = .suggestions(SearchSuggestionsFeature.State())

                return .none

            case .destination(.suggestions(.delegate(.setKeyword(let keyword)))):
                state.query = keyword
                state.destination = .results(SearchResultFeature.State(externalBooks: [
                    ExternalBook(id: "12", title: "dk232fk"),
                    ExternalBook(id: "13", title: "good-day2")
                ], keyword: keyword))
                return .none

            case .detailSheet:
                return .none

            case .destination(.results(.delegate(.tapBook(let id)))):
                state.detailSheet = ExternalBookDetailFeature.State(id: id)
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
