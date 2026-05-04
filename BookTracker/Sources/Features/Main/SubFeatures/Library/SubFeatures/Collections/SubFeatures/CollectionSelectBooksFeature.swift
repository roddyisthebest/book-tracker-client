//
//  CollectionSelectBooksFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/8/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct CollectionSelectBooksFeature {
    @Dependency(\.collectionService) var collectionService

    @ObservableState
    struct State: Equatable {
        let collection: UserCollection
        var selectedIds: Set<UUID> = []
        var books: [Book] = []

        var loadingState: LoadingState = .idle

        var isSyncing: Bool = false

        @Presents var alert: AlertState<CollectionSelectBooksFeature.Action.Alert>?
        @Presents var addBooks: AddBooksFeature.State?
    }

    enum Action: Equatable {
        case onAppear

        case loadBooks
        case loadBooksResponse(Result<[Book], AppError>)

        case syncBooksResponse(Result<Bool, AppError>)

        case bookSelected(id: UUID)
        case bookAllSelected
        case bookAllDisselected
        case addButtonTapped
        case deleteButtonTapped
        case saveButtonTapped

        case alert(PresentationAction<Alert>)
        case addBooks(PresentationAction<AddBooksFeature.Action>)

        case onRefresh

        case delegate(Delegate)
        @CasePathable
        enum Delegate: Equatable {
            case updateCollection
        }

        enum Alert {
            case confirmDeletion
        }
    }

    var body: some Reducer<State, Action> {
        Reduce {
            state, action in
            switch action {
            case .onAppear:
                return .send(.loadBooks)
            case .onRefresh:
                return .send(.onAppear)
            case .loadBooks:
                state.loadingState = .loading
                let collectionId = state.collection.id
                return .run {
                    send in
                    let result = await collectionService.listBooks(collectionId, 200, 0)
                    await send(.loadBooksResponse(result))
                }
            case .loadBooksResponse(.success(let books)):
                state.loadingState = .loaded
                state.books = books
                return .none
            case .loadBooksResponse(.failure):
                state.loadingState = .error
                return .none
            case .bookSelected(let id):
                if state.selectedIds.contains(id) {
                    state.selectedIds.remove(id)
                    return .none
                }
                state.selectedIds.insert(id)
                return .none
            case .bookAllSelected:
                state.selectedIds = Set(state.books.map { $0.id })
                return .none
            case .bookAllDisselected:
                state.selectedIds.removeAll()
                return .none
            case .addButtonTapped:
                state.addBooks = AddBooksFeature.State(unSelectableIds: Set(state.books.map { $0.id }))
                return .none
            case .deleteButtonTapped:
                state.alert = AlertState {
                    TextState("are_you_sure")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDeletion) {
                        TextState("delete")
                    }
                }
                return .none
            case .alert(.presented(.confirmDeletion)):
                state.books = state.books.filter { !state.selectedIds.contains($0.id) }
                state.selectedIds = []
                return .none
            case .alert:
                return .none
            case .addBooks(.presented(.delegate(.addBooksToCollection(let books)))):
                state.books.append(contentsOf: books)
                state.addBooks = nil
                return .none
            case .saveButtonTapped:
                state.isSyncing = true
                let collectionId = state.collection.id
                let bookIds = Array(Set(state.books.map { $0.id }))
                return .run {
                    send in
                    let result = await collectionService.syncBooks(collectionId, bookIds)
                    await send(.syncBooksResponse(result))
                }
            case .syncBooksResponse(.success):
                state.isSyncing = false
                return .send(.delegate(.updateCollection))
            case .syncBooksResponse(.failure):
                state.isSyncing = false
                state.alert = .showSyncingFailedAlert()
                return .none
            case .delegate:
                return .none
            case .addBooks:
                return .none
            }
        }
        .ifLet(\.$addBooks, action: \.addBooks) {
            AddBooksFeature()
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

extension CollectionSelectBooksFeature.State {
    var isAllSelected: Bool {
        if books.isEmpty {
            return false
        }

        return books.count == selectedIds.count
    }

    var isSubmitEnabled: Bool {
        selectedIds.count > 0
    }

    func isSelected(id: UUID) -> Bool {
        selectedIds.contains(id)
    }
}

extension AlertState where Action == CollectionSelectBooksFeature.Action.Alert {
    static func showSyncingFailedAlert() -> Self {
        Self {
            TextState("sync_failed")
        }
    }
}
