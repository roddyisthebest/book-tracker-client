//
//  BookFormFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/12/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct BookFormFeature {
    @Dependency(\.bookService) var bookService

    @ObservableState
    struct State: Equatable {
        let externalId: String
        var externalBook: ExternalBook?
        let bookId: UUID?

        var changeMode: BookStatus? = nil

        var status: BookStatus = .done
        var type: BookType = .paper

        var progress: Double = 0.0
        var page: String = "0"
        var entirePage: String = "216"

        var rating: Double = 0.0
        var startedAt: Date = .init()
        var endedAt: Date = .init()

        var reason: String = ""
        var note: String = ""
        var reviewComment: String = ""
        var isLoading: Bool = false

        var pageCountEditable: Bool = false

        // Change-mode helpers
        var isChangeModeActive: Bool { changeMode != nil }
        var title: String {
            guard let mode = changeMode else {
                if isEditing {
                    return String(localized: "book_edit")
                } else {
                    return String(localized: "book_add")
                }
            }
            let label: String
            switch mode {
            case .done: label = String(localized: "change_status_done")
            case .reading: label = String(localized: "change_status_reading")
            case .dropped: label = String(localized: "change_status_dropped")
            case .want: label = String(localized: "change_status_want")
            }
            return String(format: String(localized: "change_status_title %@"), label)
        }

        @Presents var destination: Destination.State?
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case addButtonTapped
        case saveButtonTapped
        case creationResponse(Result<Book, AppError>)
        case updateResponse(Result<Book, AppError>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case confirmCreation(Book)
            case confirmUpdate(Book)
        }

        case destination(PresentationAction<Destination.Action>)
        enum Alert: Equatable {
            case confirmError
            case confirmCreation(Book)
            case confirmUpdate(Book)
        }
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .addButtonTapped:
                state.isLoading = true
                let newBook = state.toNewBook()
                return .run { [newBook, bookService] send in
                    let result = try await bookService.create(newBook)
                    await send(.creationResponse(result))
                }
            case .saveButtonTapped:
                guard let id = state.bookId else { return .none }
                state.isLoading = true
                let updatedBook = state.toPatch()
                return .run {
                    [id, updatedBook, bookService] send in
                    let result = try await bookService.update(id, updatedBook)
                    await send(.updateResponse(result))
                }
            case .creationResponse(let result):
                state.isLoading = false
                switch result {
                case .success(let book):
                    state.destination = .alert(.showCreationMessage(new: book))
                    return .none
                case .failure(let error):
                    switch error {
                    case .storage(_, _, let message):
                        state.destination = .alert(.showErrorMessage(message: message))
                        return .none
                    case .auth(_, _, let message):
                        state.destination = .alert(.showErrorMessage(message: message))
                        return .none
                    default:
                        return .none
                    }
                }
            case .updateResponse(let result):
                state.isLoading = false
                switch result {
                case .success(let book):
                    state.destination = .alert(.showUpdateMessage(updated: book))
                    return .none
                case .failure(let error):
                    switch error {
                    case .storage(_, _, let message):
                        state.destination = .alert(.showErrorMessage(message: message))
                        return .none
                    case .auth(_, _, let message):
                        state.destination = .alert(.showErrorMessage(message: message))
                        return .none
                    default:
                        return .none
                    }
                }
            case .destination(.presented(.alert(.confirmCreation(let book)))):
                return .run {
                    send in
                    await send(.delegate(.confirmCreation(book)))
                }
            case .destination(.presented(.alert(.confirmUpdate(let book)))):
                return .run {
                    send in
                    await send(.delegate(.confirmUpdate(book)))
                }
            case .binding(\.status):
                if let forced = state.changeMode {
                    // Prevent changing status when change mode is active
                    state.status = forced
                }
                return .none
            case .binding(\.progress):
                let pageValue = Double(max(Int(state.entirePage) ?? 100, 0)) * (max(state.progress, 0) * 0.01)
                let pageInt = Int(pageValue)
                state.page = String(pageInt)
                return .none
            case .binding(\.page):
                if let pageInt = Int(state.page), let entirePageInt = Int(state.entirePage) {
                    let page = min(max(pageInt, 0), entirePageInt)
                    let progress = (Double(page) / max(Double(entirePageInt), 1.0)) * 100.0
                    state.progress = progress
                } else {
                    state.progress = 0
                }
                return .none
            case .binding:
                return .none
            case .delegate:
                return .none
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension BookFormFeature {
    @Reducer(state: .equatable, action: .equatable)
    enum Destination {
        case alert(AlertState<BookFormFeature.Action.Alert>)
    }
}

extension BookFormFeature.State {
    var isEditing: Bool { bookId != nil }

    // 생성 요청에 사용할 Book 도메인 모델 구성
    func toNewBook() -> Book {
        Book(
            id: UUID(),
            userId: UUID(), // TODO: AuthService 연동 시 실제 유저 ID 주입
            externalBookId: externalId,
            title: externalBook?.title ?? "",
            author: externalBook?.authors?.first ?? "",
            publisher: externalBook?.publisher ?? "",
            pageCount: Int(entirePage),
            pageCountEditable: pageCountEditable,
            imageUrl: externalBook?.thumbnail?.absoluteString ?? "",
            isbn: externalBook?.isbn13 ?? "",
            status: status,
            type: type,
            startedAt: status == .reading || status == .done ? startedAt : nil,
            readCount: status == .reading ? Int(page) : nil,
            memo: note.isEmpty ? nil : note,
            endedAt: status == .done ? endedAt : nil,
            score: status == .done ? (rating == 0 ? nil : rating) : nil,
            review: reviewComment.isEmpty ? nil : reviewComment,
            droppedReason: status == .dropped ? (reason.isEmpty ? nil : reason) : nil,
        )
    }

    // 수정 요청에 사용할 Patch 모델 구성
    func toPatch() -> BookPatch {
        BookPatch(
            pageCount: status == .reading ? Int(entirePage) : nil, status: status,
            type: type,
            memo: note.isEmpty ? nil : note,
            droppedReason: status == .dropped ? (reason.isEmpty ? nil : reason) : nil,
            startedAt: status == .reading || status == .done ? startedAt : nil,
            endedAt: status == .done ? endedAt : nil,
            readCount: status == .reading ? Int(page) : nil,
            score: status == .done ? (rating == 0 ? nil : rating) : nil,
            review: reviewComment.isEmpty ? nil : reviewComment
        )
    }
}

extension BookFormFeature.State {
    // create
    init(externalId: String, externalBook: ExternalBook, now: Date = Date()) {
        self.externalId = externalId

        self.entirePage = externalBook.pageCount.map(String.init) ?? "100"
        self.bookId = nil
        self.externalBook = externalBook

        self.pageCountEditable = externalBook.pageCount == nil
        self.startedAt = now
        self.endedAt = now
    }

    // update
    init(externalId: String, bookId: UUID, book: Book, changeMode: BookStatus?, now: Date = Date()) {
        self.bookId = bookId
        self.externalId = externalId

        if let changeMode = changeMode {
            self.status = changeMode
            self.changeMode = changeMode
        } else {
            self.status = book.status
        }
        self.type = book.type

        let pageCount = book.pageCount ?? 100
        let readCount = book.readCount ?? 0

        self.entirePage = String(pageCount)
        self.page = String(readCount)

        self.progress = (Double(readCount) / Double(pageCount)) * 100

        self.rating = book.score ?? 0
        self.startedAt = book.startedAt ?? now
        self.endedAt = book.endedAt ?? now

        self.reason = book.droppedReason ?? ""
        self.note = book.memo ?? ""
        self.reviewComment = book.review ?? ""
        self.pageCountEditable = book.pageCountEditable
    }
}

extension AlertState where Action == BookFormFeature.Action.Alert {
    static func showErrorMessage(message: String?) -> Self {
        Self {
            TextState(message ?? String(localized: "error_title"))
        } actions: {
            ButtonState(role: .cancel) {
                TextState("confirm")
            }
        }
    }

    static func showCreationMessage(new: Book) -> Self {
        Self {
            TextState("book_added_success")
        } actions: {
            ButtonState(role: .cancel, action: .confirmCreation(new)) {
                TextState("confirm")
            }
        }
    }

    static func showUpdateMessage(updated: Book) -> Self {
        Self {
            TextState("book_updated_success")
        } actions: {
            ButtonState(role: .cancel, action: .confirmUpdate(updated)) {
                TextState("confirm")
            }
        }
    }
}
