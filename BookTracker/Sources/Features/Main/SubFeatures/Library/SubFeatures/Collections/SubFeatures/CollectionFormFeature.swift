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
    @ObservableState
    struct State: Equatable {
        var id: UUID?

        var title: String = ""
        var description: String = ""
        var isDefault: Bool = false
        @Presents var alert: AlertState<CollectionFormFeature.Action.Alert>?

        var isEditing: Bool {
            id != nil
        }

        var isSubmitEnabled: Bool {
            !title.isEmpty && !description.isEmpty
        }

        init() {}

        init(
            collection: Collection
        ) {
            self.id = collection.id
            self.title = collection.title
            self.description = collection.description
            self.isDefault = collection.isDefault
        }
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)

        case deleteButtonTapped
        case createButtonTapped
        case updateButtonTapped

        case alert(PresentationAction<Alert>)

        case delegate(Delegate)

        enum Alert: Equatable {
            case confirmDeletion
        }

        enum Delegate: Equatable {
            case deleteCollection(id: UUID)
            case updateCollection(updated: Collection)
            case createCollection(new: Collection)
        }
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .createButtonTapped:
                let new = Collection(id: UUID(5), isDefault: false, title: state.title, description: state.description)

                return .send(.delegate(.createCollection(new: new)))
            case .updateButtonTapped:
                guard let id = state.id else {
                    return .none
                }
                let updated = Collection(id: id, isDefault: state.isDefault, title: state.title, description: state.description)
                return .send(.delegate(.updateCollection(updated: updated)))
            case .deleteButtonTapped:
                state.alert = AlertState {
                    TextState("Are you sure?")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDeletion) {
                        TextState("Delete")
                    }
                }
                return .none
            case .binding:
                return .none
            case .alert(.presented(.confirmDeletion)):
                guard let id = state.id else {
                    return .none
                }
                return .send(.delegate(.deleteCollection(id: id)))
            case .delegate:
                return .none
            default:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
