//
//  CollectionFormFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/7/26.
//
import ComposableArchitecture
import Foundation

@Reducer
struct CollectionFormFeature {
    @Dependency(\.collectionService) var collectionService

    @ObservableState
    struct State: Equatable {
        var id: UUID?

        var title: String = ""
        var description: String = ""
        var isDefault: Bool = false

        var isLoading: Bool = false
        var selectedBookIds: Set<UUID> = []

        @Presents var alert: AlertState<CollectionFormFeature.Action.Alert>?
        @Presents var addBooks: AddBooksFeature.State?

        init() {}

        init(
            collection: UserCollection
        ) {
            self.id = collection.id
            self.title = collection.name ?? ""
            self.description = collection.description ?? ""
            self.isDefault = collection.isDefault
        }
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)

        case createButtonTapped
        case updateButtonTapped

        case presentBookPickerButtonTapped

        case creationResponse(Result<UserCollection, AppError>)
        case updateResponse(Result<UserCollection, AppError>)

        case alert(PresentationAction<Alert>)
        case addBooks(PresentationAction<AddBooksFeature.Action>)

        case delegate(Delegate)

        enum Alert: Equatable {
            case confirmCreation
        }

        enum Delegate: Equatable {
            case refreshCollection
            case updateCollection(collection: UserCollection)
            case deleteCollection(id: UUID)
        }
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .createButtonTapped:
                if state.id != nil {
                    return .none
                }

                if state.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || state.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                {
                    return .none
                }
                let new = NewCollection(name: state.title, description: state.description, isDefault: false)
                state.isLoading = true
                return .run {
                    [new = new, ids = Array(state.selectedBookIds)] send in
                    let result = try await collectionService.createWithBooks(new, ids)
                    await send(.creationResponse(result))
                }
            case .updateButtonTapped:
                guard let id = state.id else {
                    return .none
                }

                if state.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || state.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                {
                    return .none
                }

                let patch = CollectionPatch(name: state.title, description: state.description, isDefault: state.isDefault)

                state.isLoading = true
                return .run {
                    [id = id] send in
                    let result = try await collectionService.update(id, patch)
                    await send(.updateResponse(result))
                }
            case .binding:
                return .none
            case .presentBookPickerButtonTapped:
                state.addBooks = AddBooksFeature.State(selectedIds: state.selectedBookIds)
                return .none
            case .addBooks(.presented(.delegate(.addBooksToCollection(let books)))):
                state.selectedBookIds = Set(books.map { $0.id })
                state.addBooks = nil
                return .none
            case .creationResponse(.success(let collection)):
                state.isLoading = false
                state.alert = .showCreateConfirmation()

                return .none
            case .creationResponse(.failure):
                state.isLoading = false
                state.alert = .showCreationErrorAlert()
                return .none
            case .updateResponse(.success(let collection)):
                state.isLoading = false
                return .send(.delegate(.updateCollection(collection: collection)))
            case .updateResponse(.failure):
                state.isLoading = false
                state.alert = .showUpdateErrorAlert()
                return .none
            case .alert(.presented(.confirmCreation)):
                return .send(.delegate(.refreshCollection))
            case .delegate:
                return .none
            case .addBooks:
                return .none
            case .alert:
                return .none
            }
        }
        .ifLet(\.$addBooks, action: \.addBooks) {
            AddBooksFeature()
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

extension CollectionFormFeature.State {
    var isEditing: Bool {
        id != nil
    }

    var isSubmitEnabled: Bool {
        !title.isEmpty && !description.isEmpty
    }
}

extension AlertState where Action == CollectionFormFeature.Action.Alert {
    static func showCreateConfirmation() -> Self {
        Self {
            TextState("collection_created")
        } actions: {
            ButtonState(action: .confirmCreation) {
                TextState("confirm")
            }
        }
    }

    static func showCreationErrorAlert() -> Self {
        Self {
            TextState("book_create_failed")
        }
    }

    static func showUpdateErrorAlert() -> Self {
        Self {
            TextState("book_update_failed")
        }
    }

    static func showDeletionErrorAlert() -> Self {
        Self {
            TextState("book_delete_failed")
        }
    }
}
