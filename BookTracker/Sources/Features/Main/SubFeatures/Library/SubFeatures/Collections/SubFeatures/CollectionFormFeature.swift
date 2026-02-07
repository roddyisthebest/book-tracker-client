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
        let id: UUID?

        var name: String
        var description: String
        @Presents var alert: AlertState<CollectionFormFeature.Action.Alert>?

        var isEditing: Bool {
            id != nil
        }

        var isSubmitEnabled: Bool {
            !name.isEmpty && !description.isEmpty
        }

        init(
            id: UUID? = nil,
            name: String = "",
            description: String = "",
        ) {
            self.id = id
            self.name = name
            self.description = description
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
            case deleteCollection(UUID)
            case updateCollection(UUID, String, String)
            case createCollection(String, String)
        }
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .createButtonTapped:
                return .send(.delegate(.createCollection(state.name, state.description)))
            case .updateButtonTapped:
                guard let id = state.id else {
                    return .none
                }
                return .send(.delegate(.updateCollection(id, state.name, state.description)))
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
                return .run {
                    [id = id] send in
                    await send(.delegate(.deleteCollection(id)))
                }
            case .delegate:
                return .none
            default:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
