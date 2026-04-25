//
//  ReceiptCoreDataStack.swift
//  BookTracker
//
//  Created by 배성연 on 3/25/26.
//

import CoreData
import Foundation

struct ReceiptCoreDataStack {
    static let entityName = "ReceiptBook"
    static let shared = ReceiptCoreDataStack()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = Self.makeModel()
        container = NSPersistentContainer(name: "ReceiptBookModel", managedObjectModel: model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        } else {
            let storeURL: URL = {
                let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
                let appSupportURL = urls[0].appendingPathComponent("ReceiptBook", isDirectory: true)
                try? FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
                return appSupportURL.appendingPathComponent("ReceiptBook.sqlite")
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

        let typeRawValueAttribute = NSAttributeDescription()
        typeRawValueAttribute.name = "typeRawValue"
        typeRawValueAttribute.attributeType = .stringAttributeType
        typeRawValueAttribute.isOptional = false

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

        let priceAttribute = NSAttributeDescription()
        priceAttribute.name = "price"
        priceAttribute.attributeType = .integer64AttributeType
        priceAttribute.isOptional = true

        let currencyCodeAttribute = NSAttributeDescription()
        currencyCodeAttribute.name = "currencyCode"
        currencyCodeAttribute.attributeType = .stringAttributeType
        currencyCodeAttribute.isOptional = true

        entity.properties = [
            idAttribute,
            typeRawValueAttribute,
            titleAttribute,
            authorsDataAttribute,
            publisherAttribute,
            pageCountAttribute,
            thumbnailURLAttribute,
            isbn13Attribute,
            priceAttribute,
            currencyCodeAttribute,
        ]

        entity.uniquenessConstraints = [["id", "typeRawValue"]]

        let model = NSManagedObjectModel()
        model.entities = [entity]
        return model
    }
}
