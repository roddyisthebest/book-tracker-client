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
        @Presents var destination: Destination.State? = .suggestions(SearchSuggestionsFeature.State())

        @Presents var detailSheet: ExternalBookDetailFeature.State?
        @Presents var customBookForm: CustomBookFormFeature.State?
        @Presents var customBookList: CustomBookListFeature.State?
    }

    enum Action: Equatable, BindableAction {
        case detailSheet(PresentationAction<ExternalBookDetailFeature.Action>)
        case customBookForm(PresentationAction<CustomBookFormFeature.Action>)
        case customBookList(PresentationAction<CustomBookListFeature.Action>)
        case destination(PresentationAction<Destination.Action>)
        case queryResetButtonTapped
        case binding(BindingAction<State>)
    }

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding(\.query):
                let trimmed = state.query.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    if case .results = state.destination {
                        state.destination = .suggestions(SearchSuggestionsFeature.State())
                    }
                    return .none
                } else {
                    if case .results = state.destination {
                        return .send(.destination(.presented(.results(.setKeyword(trimmed)))))
                    } else {
                        state.destination = .results(SearchResultFeature.State(keyword: trimmed))
                        return .send(.destination(.presented(.results(.setKeyword(trimmed)))))
                    }
                }

            case .queryResetButtonTapped:
                state.query = ""
                state.destination = .suggestions(SearchSuggestionsFeature.State())
                return .none

            case .destination(.presented(.suggestions(.delegate(.setKeyword(let keyword))))):
                state.query = keyword
                state.destination = .results(SearchResultFeature.State(keyword: keyword))
                return .send(.destination(.presented(.results(.setKeyword(keyword)))))

            case .destination(.presented(.suggestions(.delegate(.addCustomBook)))):
                state.customBookForm = CustomBookFormFeature.State()
                return .none

            case .destination(.presented(.suggestions(.delegate(.openCustomBookList)))):
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

            case .destination(.presented(.results(.delegate(.tapBook(let id))))):
                state.detailSheet = ExternalBookDetailFeature.State(id: id)
                return .none

            case .destination:
                return .none

            case .binding:
                return .none
            }
        }

        .ifLet(\.$detailSheet, action: \.detailSheet) { ExternalBookDetailFeature() }
        .ifLet(\.$customBookForm, action: \.customBookForm) { CustomBookFormFeature() }
        .ifLet(\.$customBookList, action: \.customBookList) { CustomBookListFeature() }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension SearchFeature {
    @Reducer(state: .equatable, action: .equatable)
    enum Destination {
        case suggestions(SearchSuggestionsFeature)
        case results(SearchResultFeature)
    }
}
