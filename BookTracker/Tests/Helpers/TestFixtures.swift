@testable import BookTracker
import Foundation

// MARK: - Test Fixtures

enum TestFixtures {
    // MARK: - Book

    static let bookId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let userId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

    static let book = Book(
        id: bookId,
        userId: userId,
        externalBookId: "ext-001",
        title: "Test Book",
        author: "Test Author",
        publisher: "Test Publisher",
        pageCount: 300,
        pageCountEditable: false,
        imageUrl: "https://example.com/cover.jpg",
        isbn: "9781234567890",
        status: .reading,
        type: .paper,
        startedAt: Date(timeIntervalSince1970: 1_700_000_000),
        readCount: 50,
        memo: "Test memo",
        endedAt: nil,
        score: nil,
        review: nil,
        droppedReason: nil
    )

    static let doneBook = Book(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        userId: userId,
        externalBookId: "ext-002",
        title: "Done Book",
        author: "Done Author",
        publisher: "Done Publisher",
        pageCount: 200,
        pageCountEditable: false,
        imageUrl: nil,
        isbn: "9780987654321",
        status: .done,
        type: .ebook,
        startedAt: Date(timeIntervalSince1970: 1_699_000_000),
        readCount: nil,
        memo: nil,
        endedAt: Date(timeIntervalSince1970: 1_700_000_000),
        score: 4.5,
        review: "Great book",
        droppedReason: nil
    )

    // MARK: - ExternalBook

    static let externalBook = ExternalBook(
        id: "ext-001",
        title: "External Book",
        authors: ["Author One", "Author Two"],
        publisher: "External Publisher",
        publishedDate: "2024-01-01",
        pageCount: 300,
        isbn13: "9781234567890"
    )

    // MARK: - MyProfile

    static let profileId = UUID(uuidString: "00000000-0000-0000-0000-000000000010")!

    static let profile = MyProfile(
        id: profileId,
        name: "Test User",
        role: "user",
        phoneToken: nil,
        imageUuid: nil,
        createdAt: Date(timeIntervalSince1970: 1_700_000_000),
        deletedAt: nil
    )

    static let updatedProfile = MyProfile(
        id: profileId,
        name: "Updated Name",
        role: "user",
        phoneToken: nil,
        imageUuid: nil,
        createdAt: Date(timeIntervalSince1970: 1_700_000_000),
        deletedAt: nil
    )

    // MARK: - MyAuthInfo

    static let authInfo = MyAuthInfo(
        email: "test@example.com",
        provider: "email"
    )

    // MARK: - ReadingRecord

    static let readingRecord = ReadingRecord(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000020")!,
        date: Date(timeIntervalSince1970: 1_700_000_000),
        userId: userId,
        createdAt: Date(timeIntervalSince1970: 1_700_000_000)
    )

    // MARK: - SearchKeyword

    static let searchKeyword = SearchKeyword(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000030")!,
        keyword: "swift",
        searchCount: 5,
        createdAt: Date(timeIntervalSince1970: 1_700_000_000),
        updatedAt: nil
    )

    // MARK: - ReceiptBook

    static let receiptBook = ReceiptBook(
        id: "ext-001",
        type: .purchase,
        title: "Receipt Book",
        authors: ["Author"],
        publisher: "Publisher",
        pageCount: 200,
        thumbnailURL: "https://example.com/thumb.jpg",
        isbn13: "9781234567890",
        saleInfo: ReceiptSaleInfo(amountInMicros: 15_000_000_000, currencyCode: .krw)
    )

    // MARK: - ReceiptSummary

    static let receiptSummary = ReceiptSummary(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000040")!,
        createdAt: Date(timeIntervalSince1970: 1_700_000_000),
        receiptAt: Date(timeIntervalSince1970: 1_700_000_000),
        source: "google_books",
        totalMicros: 15_000_000_000,
        totalUsdMicros: 10_000_000,
        type: .purchase,
        firstBookTitle: "Test Book",
        totalQuantity: 1,
        sourceCurrencyCode: .krw
    )

    // MARK: - ReceiptDetail

    static let receiptDetail = ReceiptDetail(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000040")!,
        createdAt: Date(timeIntervalSince1970: 1_700_000_000),
        receiptAt: Date(timeIntervalSince1970: 1_700_000_000),
        source: "google_books",
        totalMicros: 15_000_000_000,
        totalUsdMicros: 10_000_000,
        type: .purchase,
        items: [
            ReceiptDetailItem(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000041")!,
                externalBookId: "ext-001",
                title: "Test Book",
                author: "Author",
                publisher: "Publisher",
                pageCount: 200,
                imageUrl: "https://example.com/thumb.jpg",
                isbn: "9781234567890",
                quantity: 1,
                micros: 15_000_000_000,
                currencyCode: "KRW",
                usdMicros: 10_000_000,
                exchangeRateToUsd: 0.00075,
                exchangeRateDate: "2024-01-01T00:00:00Z"
            ),
        ]
    )

    // MARK: - UserCollection

    static let userCollection = UserCollection(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000060")!,
        userId: userId,
        name: "Test Collection",
        type: .custom,
        createdAt: Date(timeIntervalSince1970: 1_700_000_000),
        description: "Test description"
    )

    // MARK: - UserCollectionSummary

    static let collectionSummary = UserCollectionSummary(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000050")!,
        userId: userId,
        name: "My Collection",
        type: .custom,
        createdAt: Date(timeIntervalSince1970: 1_700_000_000),
        description: "Test collection",
        previewBooks: []
    )
}
