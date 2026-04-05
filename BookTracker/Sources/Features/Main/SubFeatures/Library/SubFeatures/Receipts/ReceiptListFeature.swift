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
    @Dependency(\.receiptService) var receiptService

    @ObservableState
    struct State: Equatable {
        @Presents var receiptDetail: ReceiptDetailFeature.State?
        @Presents var alert: AlertState<ReceiptListFeature.Action.Alert>?

        var sortOption: BookSortOption = .newest
        var receiptType: ReceiptType = .rental
        var list: [ReceiptSummary] = []

        var isLoading: Bool = false
        var isLoadingMore: Bool = false

        var isError: Bool = false

        var nextIndex: Int = 0
        var pageSize: Int = 40
        var hasMore: Bool = true
    }

    enum Action: Equatable, BindableAction {
        case onAppear

        case loadReceipts
        case loadReceiptResponse(Result<[ReceiptSummary], AppError>)

        case loadMore
        case loadMoreResponse(Result<[ReceiptSummary], AppError>)

        case onRefresh

        case binding(BindingAction<State>)
        case recepitCardTapped(ReceiptType, UUID)
        case shareTapped
        case allDeleteButtonTapped
        case deleteButtonTapped(UUID)
        case receiptDetail(PresentationAction<ReceiptDetailFeature.Action>)
        case alert(PresentationAction<Alert>)
        enum Alert: Equatable {
            case confirmAllDeletion
            case confirmDeletion(id: UUID)
        }
    }

    private enum CancelID {
        case loadReceipts
        case loadMore
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .send(.loadReceipts)
            case .onRefresh:
                return .send(.loadReceipts)
            case .loadReceipts:
                state.isLoading = true
                state.isError = false
                state.nextIndex = 0
                state.hasMore = true
                let pageSize = state.pageSize
                let type = state.receiptType
                return .merge(
                    .cancel(id: CancelID.loadReceipts),
                    .run {
                        send in
                        let result = await receiptService.loadReceipts(type, pageSize, 0)
                        await send(.loadReceiptResponse(result))
                    }
                )
            case .loadReceiptResponse(.success(let receipts)):
                state.isLoading = false
                state.list = receipts
                state.nextIndex = receipts.count
                state.hasMore = receipts.count == state.pageSize
                return .none
            case .loadReceiptResponse(.failure(let error)):
                state.isLoading = false
                state.list = []
                state.isError = true
                state.nextIndex = 0
                state.hasMore = false
                return .none
            case .loadMore:
                guard !state.isLoading,
                      !state.isLoadingMore,
                      state.hasMore
                else {
                    return .none
                }
                state.isLoadingMore = true
                let type = state.receiptType
                let pageSize = state.pageSize
                let nextIndex = state.nextIndex
                return .run { send in
                    let result = await receiptService.loadReceipts(type, pageSize, nextIndex)
                    await send(.loadMoreResponse(result))
                }
                .cancellable(id: CancelID.loadMore, cancelInFlight: true)
            case .loadMoreResponse(.success(let receipts)):
                state.isLoadingMore = false
                state.list.append(contentsOf: receipts)
                state.nextIndex += receipts.count
                state.hasMore = receipts.count == state.pageSize
                return .none
            case .loadMoreResponse(.failure(let error)):
                state.isLoadingMore = false
                state.alert = .loadMoreFailed(message: error.localizedDescription)
                return .none
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
                    ButtonState(role: .destructive, action: .confirmDeletion(id: id)) {
                        TextState("Delete")
                    }
                }
                return .none
            case .receiptDetail(.presented(.delegate(.deleteReceipt))):
                state.receiptDetail = nil
                return .send(.onRefresh)
            case .receiptDetail:
                return .none
            case .alert(.presented(.confirmAllDeletion)):
                return .none
            case .alert(.presented(.confirmDeletion(let id))):
                state.list = state.list.filter { $0.id != id }
                return .none
            case .alert:
                return .none
            case .binding(\.receiptType):
                return .send(.loadReceipts)
            case .binding:
                return .none
            }
        }
        .ifLet(\.$receiptDetail, action: \.receiptDetail) {
            ReceiptDetailFeature()
        }.ifLet(\.$alert, action: \.alert)
    }
}

extension AlertState where Action == ReceiptListFeature.Action.Alert {
    static func deleteConfirmation(id: UUID) -> Self {
        Self {
            TextState("Are you sure?")
        } actions: {
            ButtonState(role: .destructive, action: .confirmDeletion(id: id)) {
                TextState("Delete")
            }
        }
    }

    static func loadMoreFailed(message: String) -> Self {
        Self {
            TextState("더 불러오기에 실패했어요")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("확인")
            }
        } message: {
            TextState(message)
        }
    }
}
