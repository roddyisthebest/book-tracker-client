//
//  ExternalBook.swift
//  BookTracker
//
//  Created by 배성연 on 2/16/26.
//

import Foundation

/// A lightweight representation of a book coming from the Google Books API.
/// This model flattens commonly-used fields out of the `volumeInfo` payload.
struct ExternalBook: Equatable, Identifiable, Decodable {
    let id: String
    let title: String

    // Optional metadata
    let authors: [String]?
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let pageCount: Int?
    let categories: [String]?
    let smallThumbnail: URL?
    let thumbnail: URL?
    let language: String?
    let previewLink: URL?
    let infoLink: URL?
    let canonicalVolumeLink: URL?
    let isbn13: String?
    let saleInfo: SaleInfo?

    var isCustom: Bool { id.hasPrefix("custom_") }

    // MARK: - Manual initializer to keep call sites simple

    init(
        id: String,
        title: String,
        authors: [String]? = nil,
        publisher: String? = nil,
        publishedDate: String? = nil,
        description: String? = nil,
        pageCount: Int? = nil,
        categories: [String]? = nil,
        smallThumbnail: URL? = nil,
        thumbnail: URL? = nil,
        language: String? = nil,
        previewLink: URL? = nil,
        infoLink: URL? = nil,
        canonicalVolumeLink: URL? = nil,
        isbn13: String? = nil,
        saleInfo: SaleInfo? = nil
    ) {
        self.id = id
        self.title = title
        self.authors = authors
        self.publisher = publisher
        self.publishedDate = publishedDate
        self.description = description
        self.pageCount = pageCount
        self.categories = categories
        self.smallThumbnail = smallThumbnail
        self.thumbnail = thumbnail
        self.language = language
        self.previewLink = previewLink
        self.infoLink = infoLink
        self.canonicalVolumeLink = canonicalVolumeLink
        self.isbn13 = isbn13
        self.saleInfo = saleInfo
    }

    // Upgrade potentially insecure HTTP URLs to HTTPS to satisfy ATS
    private static func upgradeToHTTPS(_ url: URL?) -> URL? {
        guard let url else { return nil }
        var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        comps?.scheme = "https"
        return comps?.url ?? url
    }

    struct SaleInfo: Equatable, Decodable {
        let country: String?
        let saleability: String?
        let isEbook: Bool?
        let listPrice: Money?
        let retailPrice: Money?
        let buyLink: URL?
        let offers: [Offer]?

        struct Money: Equatable, Decodable {
            let amount: Double?
            let currencyCode: String?
        }

        struct MoneyMicros: Equatable, Decodable {
            let amountInMicros: Int64?
            let currencyCode: String?
        }

        struct Offer: Equatable, Decodable {
            let finskyOfferType: Int?
            let listPrice: MoneyMicros?
            let retailPrice: MoneyMicros?
        }

        private enum CodingKeys: String, CodingKey {
            case country
            case saleability
            case isEbook
            case listPrice
            case retailPrice
            case buyLink
            case offers
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.country = try? c.decode(String.self, forKey: .country)
            self.saleability = try? c.decode(String.self, forKey: .saleability)
            self.isEbook = try? c.decode(Bool.self, forKey: .isEbook)
            self.listPrice = try? c.decode(Money.self, forKey: .listPrice)
            self.retailPrice = try? c.decode(Money.self, forKey: .retailPrice)
            let rawBuy = try? c.decode(URL.self, forKey: .buyLink)
            self.buyLink = ExternalBook.upgradeToHTTPS(rawBuy)
            self.offers = try? c.decode([Offer].self, forKey: .offers)
        }
    }

    // MARK: - Decoding from Google Books JSON

    private enum CodingKeys: String, CodingKey {
        case id
        case volumeInfo
        case saleInfo
    }

    private enum VolumeInfoKeys: String, CodingKey {
        case title
        case authors
        case publisher
        case publishedDate
        case description
        case pageCount
        case categories
        case imageLinks
        case language
        case previewLink
        case infoLink
        case canonicalVolumeLink
        case industryIdentifiers
    }

    private enum ImageLinksKeys: String, CodingKey {
        case smallThumbnail
        case thumbnail
    }

    private struct IndustryIdentifier: Decodable {
        let type: String?
        let identifier: String?
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)

        let volume = try container.nestedContainer(keyedBy: VolumeInfoKeys.self, forKey: .volumeInfo)
        self.title = (try? volume.decode(String.self, forKey: .title)) ?? ""

        self.authors = try? volume.decode([String].self, forKey: .authors)
        self.publisher = try? volume.decode(String.self, forKey: .publisher)
        self.publishedDate = try? volume.decode(String.self, forKey: .publishedDate)
        self.description = try? volume.decode(String.self, forKey: .description)
        self.pageCount = try? volume.decode(Int.self, forKey: .pageCount)
        self.categories = try? volume.decode([String].self, forKey: .categories)
        self.language = try? volume.decode(String.self, forKey: .language)
        self.previewLink = Self.upgradeToHTTPS(try? volume.decode(URL.self, forKey: .previewLink))
        self.infoLink = Self.upgradeToHTTPS(try? volume.decode(URL.self, forKey: .infoLink))
        self.canonicalVolumeLink = Self.upgradeToHTTPS(try? volume.decode(URL.self, forKey: .canonicalVolumeLink))

        if let imageLinks = try? volume.nestedContainer(keyedBy: ImageLinksKeys.self, forKey: .imageLinks) {
            self.smallThumbnail = Self.upgradeToHTTPS(try? imageLinks.decode(URL.self, forKey: .smallThumbnail))
            self.thumbnail = Self.upgradeToHTTPS(try? imageLinks.decode(URL.self, forKey: .thumbnail))
        } else {
            self.smallThumbnail = nil
            self.thumbnail = nil
        }

        if let identifiers = try? volume.decode([IndustryIdentifier].self, forKey: .industryIdentifiers) {
            self.isbn13 = identifiers.first(where: { $0.type == "ISBN_13" })?.identifier
        } else {
            self.isbn13 = nil
        }
        self.saleInfo = try? container.decode(SaleInfo.self, forKey: .saleInfo)
    }
}

extension ExternalBook.SaleInfo {
    init(
        country: String? = nil,
        saleability: String? = nil,
        isEbook: Bool? = nil,
        listPrice: Money? = nil,
        retailPrice: Money? = nil,
        buyLink: URL? = nil,
        offers: [Offer]? = nil
    ) {
        self.country = country
        self.saleability = saleability
        self.isEbook = isEbook
        self.listPrice = listPrice
        self.retailPrice = retailPrice
        self.buyLink = buyLink
        self.offers = offers
    }
}

// MARK: - Sample (from provided dataset)

extension ExternalBook {
    static let sample = ExternalBook(
        id: "RaeV0QEACAAJ",
        title: "자몽 살구 클럽",
        authors: ["HANRORO. HANRORO"],
        publisher: "AUTHENTIC",
        publishedDate: "2025-07-25",
        description: "A story about four suicidal girls who decide to live. The first novel by singer-songwriter Hanroro. On the last day of the club recruitment, 14-year-old So Ha joins the \"Grapefruit Apricot Club\" after reading their poster. The four members, So Ha, Tae Su, Yu Min, and Bo Hyeon, each struggle with pain but choose to help each other live.",
        pageCount: 199,
        categories: ["Fiction / General"],
        smallThumbnail: URL(string: "https://books.google.com/books/content?id=RaeV0QEACAAJ&printsec=frontcover&img=1&zoom=5&imgtk=AFLRE71L1x6H-kS_pxkFwPK5-n8q9G6sVMhqnoTKCgE_n4VIvUhwtW-2kU24oLeyhGcm6mv6kQ28kYQy9Si_5kobKBt6qMmIcAGYUa0H3Wp1X-UyM6rLb6wh_nIzK8PLgWNVIozZK_bz&source=gbs_api"),
        thumbnail: URL(string: "https://books.google.com/books/content?id=RaeV0QEACAAJ&printsec=frontcover&img=1&zoom=1&imgtk=AFLRE71iqopOJJV3mIMYdn1FVVIV8qDgFt8o1tQqlVTCdLvA7WhZr2wNc5Nb7wvcXPLfJArD_mucfk7OUkfGS-_BGXLvihhWQV7y-SraQaqQ9DyHD5qGz53wYvAEjk2Ct3Li9Kcofyge&source=gbs_api"),
        language: "ko",
        previewLink: URL(string: "https://books.google.co.kr/books?id=RaeV0QEACAAJ&hl=&source=gbs_api"),
        infoLink: URL(string: "https://play.google.com/store/books/details?id=RaeV0QEACAAJ&source=gbs_api"),
        canonicalVolumeLink: URL(string: "https://play.google.com/store/books/details?id=RaeV0QEACAAJ"),
        isbn13: "9791199305304",
        saleInfo: SaleInfo(
            country: "KR",
            saleability: "FOR_SALE",
            isEbook: true,
            listPrice: SaleInfo.Money(amount: 15000, currencyCode: "KRW"),
            retailPrice: SaleInfo.Money(amount: 12000, currencyCode: "KRW"),
            buyLink: URL(string: "https://play.google.com/store/books/details?id=RaeV0QEACAAJ"),
            offers: [
                SaleInfo.Offer(
                    finskyOfferType: 1,
                    listPrice: SaleInfo.MoneyMicros(amountInMicros: 15_000_000, currencyCode: "KRW"),
                    retailPrice: SaleInfo.MoneyMicros(amountInMicros: 12_000_000_000, currencyCode: "KRW")
                )
            ]
        )
    )
}

extension ExternalBook {
    func toReceiptBook(type: ReceiptType) -> ReceiptBook {
        ReceiptBook(
            externalBook: self,
            type: type
        )
    }

    func toReceiptBook(type: ReceiptType, amountInMicros: Int64, currencyCode: CurrencyCode) -> ReceiptBook {
        ReceiptBook(
            externalBook: self,
            type: type,
            amountInMicros: amountInMicros,
            currencyCode: currencyCode
        )
    }
}

//
// extension ReceiptBook {
//    func toBook(
//        memo: String
//    ) -> Book {
//        Book(
//            id: UUID(),
//            userId: UUID(),
//            externalBookId: id,
//            title: title,
//            author: authorText ?? "",
//            publisher: publisher ?? "",
//            pageCount: pageCount,
//            pageCountEditable: pageCount != nil,
//            imageUrl: thumbnailURL ?? "",
//            isbn: isbn13 ?? "",
//            status: .want,
//            type: .paper,
//            startedAt: nil,
//            readCount: nil,
//            memo: memo,
//            endedAt: nil,
//            score: nil,
//            review: nil,
//            droppedReason: nil
//        )
//    }
// }
