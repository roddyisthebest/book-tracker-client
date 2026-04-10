//
//  DataManageFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/22/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct DataManageFeature {
    @Dependency(\.bookService) var bookService

    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<Action.Alert>?
        var isSharePresented: Bool = false
        var isExporting: Bool = false
        var exportFilePath: String? = nil
    }

    enum Action: Equatable {
        case shareDismissed
        case csvExportButtonTapped
        case csvExportResponse(Result<String, AppError>)
        case dataResetButtonTapped
        case alert(PresentationAction<Alert>)
        enum Alert: Equatable {
            case confirmResetData
        }
    }

    var body: some Reducer<State, Action> {
        Reduce<State, Action> {
            state, action in
            switch action {
            case .shareDismissed:
                state.isSharePresented = false
                return .none
            case .csvExportButtonTapped:
                state.isExporting = true
                state.exportFilePath = nil
                return .run { [bookService] send in
                    do {
                        let result = try await bookService.list(nil, .newest, 3000, 0)
                        switch result {
                        case .success(let books):
                            let csv = makeBooksCSV(books)
                            let url = try writeCSVToTemporaryFile(csv)
                            await send(.csvExportResponse(.success(url.path)))
                        case .failure(let error):
                            await send(.csvExportResponse(.failure(error)))
                        }
                    } catch {
                        await send(.csvExportResponse(.failure(.storage(code: "UNKNOWN", status: nil, message: error.localizedDescription))))
                    }
                }
            case .csvExportResponse(.success(let path)):
                state.isExporting = false
                state.exportFilePath = path
                state.isSharePresented = true
                return .none
            case .csvExportResponse(.failure):
                state.isExporting = false
                return .none
            case .dataResetButtonTapped:
                state.alert = .confirmResetData()
                return .none
            case .alert(.presented(.confirmResetData)):
                return .none
            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

extension AlertState where Action == DataManageFeature.Action.Alert {
    static func confirmResetData() -> Self {
        Self {
            TextState("confirm_data_reset")
        } actions: {
            ButtonState(role: .destructive, action: .confirmResetData) {
                TextState("reset")
            }
        }
    }
}

private func makeBooksCSV(_ books: [Book]) -> String {
    var rows: [String] = []
    // Header
    rows.append([
        "id", "title", "author", "publisher", "status", "type", "pageCount", "isbn",
        "startedAt", "endedAt", "readCount", "score", "review", "memo", "createdAt",
        "externalBookId", "imageUrl", "droppedReason"
    ].joined(separator: ","))

    let iso = ISO8601DateFormatter()

    for b in books {
        let cols: [String] = [
            escapeCSV(b.id.uuidString),
            escapeCSV(b.title),
            escapeCSV(b.author),
            escapeCSV(b.publisher),
            escapeCSV(BookService.mapStatusToDB(b.status)),
            escapeCSV(BookService.mapTypeToDB(b.type)),
            escapeCSV(b.pageCount.map(String.init) ?? ""),
            escapeCSV(b.isbn),
            escapeCSV(b.startedAt.map { iso.string(from: $0) } ?? ""),
            escapeCSV(b.endedAt.map { iso.string(from: $0) } ?? ""),
            escapeCSV(b.readCount.map(String.init) ?? ""),
            escapeCSV(b.score.map { String($0) } ?? ""),
            escapeCSV(b.review ?? ""),
            escapeCSV(b.memo ?? ""),
            escapeCSV(b.createdAt.map { iso.string(from: $0) } ?? ""),
            escapeCSV(b.externalBookId ?? ""),
            escapeCSV(b.imageUrl ?? ""),
            escapeCSV(b.droppedReason ?? "")
        ]
        rows.append(cols.joined(separator: ","))
    }
    return rows.joined(separator: "\n")
}

private func escapeCSV(_ value: String) -> String {
    // Always quote and escape quotes
    let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
    return "\"\(escaped)\""
}

private func writeCSVToTemporaryFile(_ content: String) throws -> URL {
    let tempDir = FileManager.default.temporaryDirectory
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd_HHmmss"
    let fileName = "books_export_\(formatter.string(from: Date())).csv"
    let url = tempDir.appendingPathComponent(fileName)
    let data = Data(content.utf8)
    try data.write(to: url, options: [.atomic])
    return url
}
