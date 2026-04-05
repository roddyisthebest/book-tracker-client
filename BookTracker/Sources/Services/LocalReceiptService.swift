//
//  LocalReceiptService.swift
//  BookTracker
//
//  Created by 배성연 on 3/25/26.
//
import ComposableArchitecture
import CoreData
import Foundation

enum LocalReceiptError: Error, Equatable {
    case coreData(String)
    case encodingFailed
    case decodingFailed
    case unknown
}

struct LocalReceiptService {
    var fetchAll: () async -> Result<[ReceiptBook], LocalReceiptError>
    var fetchBooks: (_ type: ReceiptType) async -> Result<[ReceiptBook], LocalReceiptError>

    var save: (_ externalBook: ExternalBook, _ type: ReceiptType) async -> Result<ReceiptType, LocalReceiptError>

    var saveReceiptBook: (_ receiptBook: ReceiptBook) async -> Result<ReceiptBook, LocalReceiptError>

    var remove: (_ externalBookId: String, _ type: ReceiptType) async -> Result<String, LocalReceiptError>
    var removeSpecificTypes: (_ type: ReceiptType) async -> Result<Bool, LocalReceiptError>
    var removeAllTypes: (_ externalBookId: String) async -> Result<Void, LocalReceiptError>
    var clearAll: () async -> Result<Void, LocalReceiptError>

    var contains: (_ externalBookId: String, _ type: ReceiptType) async -> Result<Bool, LocalReceiptError>
    var registeredTypes: (_ externalBookId: String) async -> Result<[ReceiptType], LocalReceiptError>

    var isRegisteredInPurchase: (_ externalBookId: String) async -> Result<Bool, LocalReceiptError>
    var isRegisteredInRental: (_ externalBookId: String) async -> Result<Bool, LocalReceiptError>

    var count: (_ type: ReceiptType) async -> Result<Int, LocalReceiptError>
    var counts: () async -> Result<[ReceiptType: Int], LocalReceiptError>
}

extension LocalReceiptService {
    static func live(
        container: NSPersistentContainer = ReceiptCoreDataStack.shared.container
    ) -> Self {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        func entityFetchRequest() -> NSFetchRequest<NSManagedObject> {
            NSFetchRequest<NSManagedObject>(entityName: ReceiptCoreDataStack.entityName)
        }

        func toDomain(_ obj: NSManagedObject) throws -> ReceiptBook {
            let id = obj.value(forKey: "id") as? String ?? ""
            let typeRawValue = obj.value(forKey: "typeRawValue") as? String ?? ReceiptType.purchase.rawValue
            let title = obj.value(forKey: "title") as? String ?? ""
            let authorsData = obj.value(forKey: "authorsData") as? Data
            let publisher = obj.value(forKey: "publisher") as? String
            let pageCountNumber = obj.value(forKey: "pageCount") as? NSNumber
            let thumbnailURL = obj.value(forKey: "thumbnailURL") as? String
            let isbn13 = obj.value(forKey: "isbn13") as? String
            let amountInMicrosNumber = obj.value(forKey: "amountInMicros") as? NSNumber
            let currencyCode = obj.value(forKey: "currencyCode") as? String

            let authors: [String]
            if let authorsData {
                do {
                    authors = try JSONDecoder().decode([String].self, from: authorsData)
                } catch {
                    throw LocalReceiptError.decodingFailed
                }
            } else {
                authors = []
            }

            return ReceiptBook(
                id: id,
                type: ReceiptType(rawValue: typeRawValue) ?? .purchase,
                title: title,
                authors: authors,
                publisher: publisher,
                pageCount: pageCountNumber?.intValue,
                thumbnailURL: thumbnailURL,
                isbn13: isbn13,
                saleInfo: ReceiptSaleInfo(
                    amountInMicros: amountInMicrosNumber?.intValue,
                    currencyCode: currencyCode
                )
            )
        }

        func mapError(_ error: Error) -> LocalReceiptError {
            if let error = error as? LocalReceiptError {
                return error
            }
            if let error = error as? NSError {
                return .coreData(error.localizedDescription)
            }
            return .unknown
        }

        return Self(
            fetchAll: {
                do {
                    let books = try await context.perform {
                        let request = entityFetchRequest()
                        request.sortDescriptors = [
                            NSSortDescriptor(key: "title", ascending: true)
                        ]

                        let results = try context.fetch(request)
                        return try results.map(toDomain)
                    }
                    return .success(books)
                } catch {
                    return .failure(mapError(error))
                }
            },

            fetchBooks: { type in
                do {
                    let books = try await context.perform {
                        let request = entityFetchRequest()
                        request.predicate = NSPredicate(format: "typeRawValue == %@", type.rawValue)
                        request.sortDescriptors = [
                            NSSortDescriptor(key: "title", ascending: true)
                        ]

                        let results = try context.fetch(request)
                        return try results.map(toDomain)
                    }
                    return .success(books)
                } catch {
                    return .failure(mapError(error))
                }
            },

            save: { externalBook, type in
                do {
                    try await context.perform {
                        let receiptBook = ReceiptBook(externalBook: externalBook, type: type)

                        let request = entityFetchRequest()
                        request.predicate = NSPredicate(
                            format: "id == %@ AND typeRawValue == %@",
                            receiptBook.id,
                            receiptBook.type.rawValue
                        )
                        request.fetchLimit = 1

                        let existing = try context.fetch(request).first
                        let obj: NSManagedObject

                        if let existing {
                            obj = existing
                        } else {
                            let entity = NSEntityDescription.entity(
                                forEntityName: ReceiptCoreDataStack.entityName,
                                in: context
                            )!
                            obj = NSManagedObject(entity: entity, insertInto: context)
                            obj.setValue(receiptBook.id, forKey: "id")
                            obj.setValue(receiptBook.type.rawValue, forKey: "typeRawValue")
                        }

                        obj.setValue(receiptBook.title, forKey: "title")

                        do {
                            try obj.setValue(JSONEncoder().encode(receiptBook.authors), forKey: "authorsData")
                        } catch {
                            throw LocalReceiptError.encodingFailed
                        }

                        obj.setValue(receiptBook.publisher, forKey: "publisher")
                        obj.setValue(receiptBook.pageCount, forKey: "pageCount")
                        obj.setValue(receiptBook.thumbnailURL, forKey: "thumbnailURL")
                        obj.setValue(receiptBook.isbn13, forKey: "isbn13")
                        obj.setValue(receiptBook.saleInfo?.amountInMicros, forKey: "amountInMicros")
                        obj.setValue(receiptBook.saleInfo?.currencyCode, forKey: "currencyCode")

                        try context.save()
                        try context.obtainPermanentIDs(for: [obj])
                    }
                    return .success(type)
                } catch {
                    return .failure(mapError(error))
                }
            },
            saveReceiptBook: { receiptBook in
                do {
                    try await context.perform {
                        let request = entityFetchRequest()
                        request.predicate = NSPredicate(
                            format: "id == %@ AND typeRawValue == %@",
                            receiptBook.id,
                            receiptBook.type.rawValue
                        )
                        request.fetchLimit = 1

                        let existing = try context.fetch(request).first
                        let obj: NSManagedObject

                        if let existing {
                            obj = existing
                        } else {
                            let entity = NSEntityDescription.entity(
                                forEntityName: ReceiptCoreDataStack.entityName,
                                in: context
                            )!
                            obj = NSManagedObject(entity: entity, insertInto: context)
                            obj.setValue(receiptBook.id, forKey: "id")
                            obj.setValue(receiptBook.type.rawValue, forKey: "typeRawValue")
                        }

                        obj.setValue(receiptBook.title, forKey: "title")

                        do {
                            try obj.setValue(JSONEncoder().encode(receiptBook.authors), forKey: "authorsData")
                        } catch {
                            throw LocalReceiptError.encodingFailed
                        }

                        obj.setValue(receiptBook.publisher, forKey: "publisher")
                        obj.setValue(receiptBook.pageCount, forKey: "pageCount")
                        obj.setValue(receiptBook.thumbnailURL, forKey: "thumbnailURL")
                        obj.setValue(receiptBook.isbn13, forKey: "isbn13")
                        obj.setValue(receiptBook.saleInfo?.amountInMicros, forKey: "amountInMicros")
                        obj.setValue(receiptBook.saleInfo?.currencyCode, forKey: "currencyCode")

                        try context.save()
                        try context.obtainPermanentIDs(for: [obj])
                    }
                    return .success(receiptBook)
                } catch {
                    return .failure(mapError(error))
                }
            },

            remove: { externalBookId, type in
                do {
                    try await context.perform {
                        let request = entityFetchRequest()
                        request.predicate = NSPredicate(
                            format: "id == %@ AND typeRawValue == %@",
                            externalBookId,
                            type.rawValue
                        )
                        request.fetchLimit = 1

                        if let obj = try context.fetch(request).first {
                            context.delete(obj)
                            try context.save()
                        }
                    }
                    return .success(externalBookId)
                } catch {
                    return .failure(mapError(error))
                }
            },
            removeSpecificTypes: {
                type in
                do {
                    try await context.perform {
                        let request = entityFetchRequest()
                        request.predicate = NSPredicate(
                            format: "typeRawValue == %@",
                            type.rawValue
                        )
                        let results = try context.fetch(request)
                        for obj in results {
                            context.delete(obj)
                        }

                        if context.hasChanges {
                            try context.save()
                        }
                    }
                    return .success(true)
                } catch {
                    return .failure(mapError(error))
                }
            },
            removeAllTypes: { externalBookId in
                do {
                    try await context.perform {
                        let request = entityFetchRequest()
                        request.predicate = NSPredicate(format: "id == %@", externalBookId)

                        let results = try context.fetch(request)
                        for obj in results {
                            context.delete(obj)
                        }

                        if context.hasChanges {
                            try context.save()
                        }
                    }
                    return .success(())
                } catch {
                    return .failure(mapError(error))
                }
            },

            clearAll: {
                do {
                    try await context.perform {
                        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: ReceiptCoreDataStack.entityName)
                        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetch)
                        deleteRequest.resultType = .resultTypeObjectIDs

                        let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
                        if let objectIDs = result?.result as? [NSManagedObjectID] {
                            let changes = [NSDeletedObjectsKey: objectIDs]
                            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
                        }
                    }
                    return .success(())
                } catch {
                    return .failure(mapError(error))
                }
            },

            contains: { externalBookId, type in
                do {
                    let contains = try await context.perform {
                        let request = entityFetchRequest()
                        request.predicate = NSPredicate(
                            format: "id == %@ AND typeRawValue == %@",
                            externalBookId,
                            type.rawValue
                        )
                        request.fetchLimit = 1
                        return try !context.fetch(request).isEmpty
                    }
                    return .success(contains)
                } catch {
                    return .failure(mapError(error))
                }
            },

            registeredTypes: { externalBookId in
                do {
                    let types = try await context.perform {
                        let request = entityFetchRequest()
                        request.predicate = NSPredicate(format: "id == %@", externalBookId)

                        let results = try context.fetch(request)

                        let types: [ReceiptType] = results.compactMap { obj in
                            guard let rawValue = obj.value(forKey: "typeRawValue") as? String else {
                                return nil
                            }
                            return ReceiptType(rawValue: rawValue)
                        }

                        return types
                    }
                    return .success(types)
                } catch {
                    return .failure(mapError(error))
                }
            },

            isRegisteredInPurchase: { externalBookId in
                await Self.live(container: container).contains(externalBookId, .purchase)
            },

            isRegisteredInRental: { externalBookId in
                await Self.live(container: container).contains(externalBookId, .rental)
            },

            count: { type in
                do {
                    let count = try await context.perform {
                        let request = entityFetchRequest()
                        request.predicate = NSPredicate(format: "typeRawValue == %@", type.rawValue)
                        return try context.count(for: request)
                    }
                    return .success(count)
                } catch {
                    return .failure(mapError(error))
                }
            },

            counts: {
                do {
                    let value = try await context.perform {
                        func count(for type: ReceiptType) throws -> Int {
                            let request = entityFetchRequest()
                            request.predicate = NSPredicate(format: "typeRawValue == %@", type.rawValue)
                            return try context.count(for: request)
                        }

                        return try [
                            ReceiptType.purchase: count(for: .purchase),
                            ReceiptType.rental: count(for: .rental)
                        ]
                    }
                    return .success(value)
                } catch {
                    return .failure(mapError(error))
                }
            }
        )
    }
}
