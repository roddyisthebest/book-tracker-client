//
//  LocalCustomBookService.swift
//  BookTracker
//
//  Created by Claude on 5/2/26.
//

import ComposableArchitecture
import CoreData
import Foundation

enum LocalCustomBookError: Error, Equatable {
    case coreData(String)
    case encodingFailed
    case decodingFailed
    case unknown
}

struct LocalCustomBookService {
    var fetchAll: (_ userId: String) async -> Result<[ExternalBook], LocalCustomBookError>
    var save: (_ book: ExternalBook, _ userId: String) async -> Result<ExternalBook, LocalCustomBookError>
    var remove: (_ id: String, _ userId: String) async -> Result<String, LocalCustomBookError>
    var clearAll: (_ userId: String) async -> Result<Void, LocalCustomBookError>
}

extension LocalCustomBookService {
    static func live(
        container: NSPersistentContainer = CustomBookCoreDataStack.shared.container
    ) -> Self {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        func entityFetchRequest() -> NSFetchRequest<NSManagedObject> {
            NSFetchRequest<NSManagedObject>(entityName: CustomBookCoreDataStack.entityName)
        }

        func toDomain(_ obj: NSManagedObject) throws -> ExternalBook {
            let id = obj.value(forKey: "id") as? String ?? ""
            let title = obj.value(forKey: "title") as? String ?? ""
            let authorsData = obj.value(forKey: "authorsData") as? Data
            let publisher = obj.value(forKey: "publisher") as? String
            let bookDescription = obj.value(forKey: "bookDescription") as? String
            let pageCountNumber = obj.value(forKey: "pageCount") as? NSNumber
            let thumbnailURL = obj.value(forKey: "thumbnailURL") as? String
            let isbn13 = obj.value(forKey: "isbn13") as? String
            let saleability = obj.value(forKey: "saleability") as? String
            let retailPriceAmount = obj.value(forKey: "retailPriceAmount") as? NSNumber
            let retailPriceCurrencyCode = obj.value(forKey: "retailPriceCurrencyCode") as? String
            let retailPriceMicros = obj.value(forKey: "retailPriceMicros") as? NSNumber

            let authors: [String]?
            if let authorsData {
                do {
                    authors = try JSONDecoder().decode([String].self, from: authorsData)
                } catch {
                    throw LocalCustomBookError.decodingFailed
                }
            } else {
                authors = nil
            }

            let thumbnail = thumbnailURL.flatMap { URL(string: $0) }

            var saleInfo: ExternalBook.SaleInfo? = nil
            if let amount = retailPriceAmount?.doubleValue, amount > 0 {
                let money = ExternalBook.SaleInfo.Money(amount: amount, currencyCode: retailPriceCurrencyCode)
                var offers: [ExternalBook.SaleInfo.Offer]? = nil
                if let micros = retailPriceMicros?.int64Value {
                    let moneyMicros = ExternalBook.SaleInfo.MoneyMicros(
                        amountInMicros: micros,
                        currencyCode: retailPriceCurrencyCode
                    )
                    offers = [
                        ExternalBook.SaleInfo.Offer(
                            finskyOfferType: 1,
                            listPrice: moneyMicros,
                            retailPrice: moneyMicros
                        ),
                    ]
                }
                saleInfo = ExternalBook.SaleInfo(
                    saleability: saleability,
                    retailPrice: money,
                    offers: offers
                )
            }

            return ExternalBook(
                id: id,
                title: title,
                authors: authors,
                publisher: publisher,
                description: bookDescription,
                pageCount: pageCountNumber?.intValue,
                thumbnail: thumbnail,
                isbn13: isbn13,
                saleInfo: saleInfo
            )
        }

        func mapError(_ error: Error) -> LocalCustomBookError {
            if let error = error as? LocalCustomBookError {
                return error
            }
            if let error = error as? NSError {
                return .coreData(error.localizedDescription)
            }
            return .unknown
        }

        return Self(
            fetchAll: { userId in
                do {
                    let books = try await context.perform {
                        let request = entityFetchRequest()
                        request.predicate = NSPredicate(format: "userId == %@", userId)
                        request.sortDescriptors = [
                            NSSortDescriptor(key: "createdAt", ascending: false),
                        ]

                        let results = try context.fetch(request)
                        return try results.map(toDomain)
                    }
                    return .success(books)
                } catch {
                    return .failure(mapError(error))
                }
            },

            save: { book, userId in
                do {
                    try await context.perform {
                        let request = entityFetchRequest()
                        request.predicate = NSPredicate(format: "userId == %@ AND id == %@", userId, book.id)
                        request.fetchLimit = 1

                        let existing = try context.fetch(request).first
                        let obj: NSManagedObject

                        if let existing {
                            obj = existing
                        } else {
                            let entity = NSEntityDescription.entity(
                                forEntityName: CustomBookCoreDataStack.entityName,
                                in: context
                            )!
                            obj = NSManagedObject(entity: entity, insertInto: context)
                            obj.setValue(book.id, forKey: "id")
                            obj.setValue(userId, forKey: "userId")
                            obj.setValue(Date(), forKey: "createdAt")
                        }

                        obj.setValue(book.title, forKey: "title")

                        if let authors = book.authors {
                            do {
                                try obj.setValue(JSONEncoder().encode(authors), forKey: "authorsData")
                            } catch {
                                throw LocalCustomBookError.encodingFailed
                            }
                        } else {
                            obj.setValue(nil, forKey: "authorsData")
                        }

                        obj.setValue(book.publisher, forKey: "publisher")
                        obj.setValue(book.description, forKey: "bookDescription")
                        obj.setValue(book.pageCount, forKey: "pageCount")
                        obj.setValue(book.thumbnail?.absoluteString, forKey: "thumbnailURL")
                        obj.setValue(book.isbn13, forKey: "isbn13")
                        obj.setValue(book.saleInfo?.saleability, forKey: "saleability")
                        obj.setValue(book.saleInfo?.retailPrice?.amount, forKey: "retailPriceAmount")
                        obj.setValue(book.saleInfo?.retailPrice?.currencyCode, forKey: "retailPriceCurrencyCode")
                        obj.setValue(book.saleInfo?.offers?.first?.retailPrice?.amountInMicros, forKey: "retailPriceMicros")

                        try context.save()
                        try context.obtainPermanentIDs(for: [obj])
                    }
                    return .success(book)
                } catch {
                    return .failure(mapError(error))
                }
            },

            remove: { id, userId in
                do {
                    try await context.perform {
                        let request = entityFetchRequest()
                        request.predicate = NSPredicate(format: "userId == %@ AND id == %@", userId, id)
                        request.fetchLimit = 1

                        if let obj = try context.fetch(request).first {
                            context.delete(obj)
                            try context.save()
                        }
                    }
                    return .success(id)
                } catch {
                    return .failure(mapError(error))
                }
            },

            clearAll: { userId in
                do {
                    try await context.perform {
                        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: CustomBookCoreDataStack.entityName)
                        fetchRequest.predicate = NSPredicate(format: "userId == %@", userId)
                        let batchDelete = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                        batchDelete.resultType = .resultTypeObjectIDs
                        let result = try context.execute(batchDelete) as? NSBatchDeleteResult
                        let objectIDs = result?.result as? [NSManagedObjectID] ?? []
                        NSManagedObjectContext.mergeChanges(
                            fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
                            into: [context]
                        )
                    }
                    return .success(())
                } catch {
                    return .failure(mapError(error))
                }
            },

        )
    }
}
