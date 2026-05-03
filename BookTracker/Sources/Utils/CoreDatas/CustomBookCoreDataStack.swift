//
//  CustomBookCoreDataStack.swift
//  BookTracker
//
//  Created by Claude on 5/2/26.
//

import CoreData
import Foundation

struct CustomBookCoreDataStack {
    static let entityName = "CustomBook"
    static let shared = CustomBookCoreDataStack()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = Self.makeModel()
        container = NSPersistentContainer(name: "CustomBookModel", managedObjectModel: model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        } else {
            let storeURL: URL = {
                let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
                let appSupportURL = urls[0].appendingPathComponent("CustomBook", isDirectory: true)
                try? FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
                return appSupportURL.appendingPathComponent("CustomBook.sqlite")
            }()

            let description = NSPersistentStoreDescription(url: storeURL)
            description.type = NSSQLiteStoreType
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    private static func makeModel() -> NSManagedObjectModel {
        let entity = NSEntityDescription()
        entity.name = entityName
        entity.managedObjectClassName = "NSManagedObject"

        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .stringAttributeType
        idAttribute.isOptional = false

        let titleAttribute = NSAttributeDescription()
        titleAttribute.name = "title"
        titleAttribute.attributeType = .stringAttributeType
        titleAttribute.isOptional = false

        let authorsDataAttribute = NSAttributeDescription()
        authorsDataAttribute.name = "authorsData"
        authorsDataAttribute.attributeType = .binaryDataAttributeType
        authorsDataAttribute.isOptional = true

        let publisherAttribute = NSAttributeDescription()
        publisherAttribute.name = "publisher"
        publisherAttribute.attributeType = .stringAttributeType
        publisherAttribute.isOptional = true

        let bookDescriptionAttribute = NSAttributeDescription()
        bookDescriptionAttribute.name = "bookDescription"
        bookDescriptionAttribute.attributeType = .stringAttributeType
        bookDescriptionAttribute.isOptional = true

        let pageCountAttribute = NSAttributeDescription()
        pageCountAttribute.name = "pageCount"
        pageCountAttribute.attributeType = .integer32AttributeType
        pageCountAttribute.isOptional = true

        let thumbnailURLAttribute = NSAttributeDescription()
        thumbnailURLAttribute.name = "thumbnailURL"
        thumbnailURLAttribute.attributeType = .stringAttributeType
        thumbnailURLAttribute.isOptional = true

        let isbn13Attribute = NSAttributeDescription()
        isbn13Attribute.name = "isbn13"
        isbn13Attribute.attributeType = .stringAttributeType
        isbn13Attribute.isOptional = true

        let userIdAttribute = NSAttributeDescription()
        userIdAttribute.name = "userId"
        userIdAttribute.attributeType = .stringAttributeType
        userIdAttribute.isOptional = true

        let createdAtAttribute = NSAttributeDescription()
        createdAtAttribute.name = "createdAt"
        createdAtAttribute.attributeType = .dateAttributeType
        createdAtAttribute.isOptional = true

        let saleabilityAttribute = NSAttributeDescription()
        saleabilityAttribute.name = "saleability"
        saleabilityAttribute.attributeType = .stringAttributeType
        saleabilityAttribute.isOptional = true

        let retailPriceAmountAttribute = NSAttributeDescription()
        retailPriceAmountAttribute.name = "retailPriceAmount"
        retailPriceAmountAttribute.attributeType = .doubleAttributeType
        retailPriceAmountAttribute.isOptional = true

        let retailPriceCurrencyCodeAttribute = NSAttributeDescription()
        retailPriceCurrencyCodeAttribute.name = "retailPriceCurrencyCode"
        retailPriceCurrencyCodeAttribute.attributeType = .stringAttributeType
        retailPriceCurrencyCodeAttribute.isOptional = true

        let retailPriceMicrosAttribute = NSAttributeDescription()
        retailPriceMicrosAttribute.name = "retailPriceMicros"
        retailPriceMicrosAttribute.attributeType = .integer64AttributeType
        retailPriceMicrosAttribute.isOptional = true

        entity.properties = [
            idAttribute,
            userIdAttribute,
            titleAttribute,
            authorsDataAttribute,
            publisherAttribute,
            bookDescriptionAttribute,
            pageCountAttribute,
            thumbnailURLAttribute,
            isbn13Attribute,
            createdAtAttribute,
            saleabilityAttribute,
            retailPriceAmountAttribute,
            retailPriceCurrencyCodeAttribute,
            retailPriceMicrosAttribute,
        ]

        entity.uniquenessConstraints = [["userId", "id"]]

        let model = NSManagedObjectModel()
        model.entities = [entity]
        return model
    }
}
