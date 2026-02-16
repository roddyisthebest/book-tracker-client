//
//  ReceiptListFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/4/26.
//

import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
struct ReceiptListFeature {
    @ObservableState
    struct State: Equatable {
        @Presents var receiptDetail: ReceiptDetailFeature.State?
        @Presents var alert: AlertState<ReceiptListFeature.Action.Alert>?

        var sortOption: BookSortOption = .newest

        var receiptType: ReceiptType = .rental
        var list: [Receipt] = [
            Receipt(id: UUID(1), type: .purchase, title: "효진이는"),
            Receipt(id: UUID(2), type: .rental, title: "집을 알아봅니다."),
            Receipt(id: UUID(3), type: .rental, title: "하지만"),
            Receipt(id: UUID(4), type: .purchase, title: "쉽지않아보입니다"),
            Receipt(id: UUID(5), type: .purchase, title: "화이팅")
        ]

        var computedList: [Receipt] {
            let filtered = list.filter { $0.type == receiptType }
            switch sortOption {
            case .oldest:
                return filtered
            case .newest:
                return Array(filtered.reversed())
            case .titleAsc:
                return filtered.sorted(by: { (lhs: Receipt, rhs: Receipt) in
                    lhs.title < rhs.title
                })
            case .titleDesc:
                return filtered.sorted(by: { (lhs: Receipt, rhs: Receipt) in
                    lhs.title > rhs.title
                })
            }
        }
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case recepitCardTapped(ReceiptType, UUID)
        case shareTapped
        case allDeleteButtonTapped
        case deleteButtonTapped(UUID)
        case receiptDetail(PresentationAction<ReceiptDetailFeature.Action>)
        case alert(PresentationAction<Alert>)
        enum Alert: Equatable {
            case confirmAllDeletion
            case confirmDeletion(UUID)
        }
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .recepitCardTapped(let type, let id):
                state.receiptDetail = ReceiptDetailFeature.State(id: id)
                return .none
            case .shareTapped:
                return .none
            case .allDeleteButtonTapped:
                state.alert = AlertState {
                    TextState("Are you sure?")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmAllDeletion) {
                        TextState("Delete All")
                    }
                }
                return .none
            case .deleteButtonTapped(let id):
                state.alert = AlertState {
                    TextState("Are you sure?")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDeletion(id)) {
                        TextState("Delete")
                    }
                }
                return .none
            case .receiptDetail(.presented(.delegate(.deleteReceipt(let id)))):
                state.receiptDetail = nil
                state.list = state.list.filter { $0.id != id }
                // TODO: toast 메세지 필요

                return .none
            case .receiptDetail:
                return .none
            case .alert(.presented(.confirmAllDeletion)):
                return .none
            case .alert(.presented(.confirmDeletion(let id))):
                state.list = state.list.filter { $0.id != id }
                return .none
            case .alert:
                return .none
            case .binding:
                return .none
            }
        }
        .ifLet(\.$receiptDetail, action: \.receiptDetail) {
            ReceiptDetailFeature()
        }.ifLet(\.$alert, action: \.alert)
    }
}
