import CoreData
import Foundation

struct SearchHistoryCoreDataStack {
    static let entityName = "SearchHistory"
    static let shared = SearchHistoryCoreDataStack()
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = Self.makeModel()
        container = NSPersistentContainer(name: "SearchHistoryModel", managedObjectModel: model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        } else {
            let storeURL: URL = {
                let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
                let appSupportURL = urls[0].appendingPathComponent("SearchHistory", isDirectory: true)
                try? FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
                return appSupportURL.appendingPathComponent("SearchHistory.sqlite")
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

        let textAttribute = NSAttributeDescription()
        textAttribute.name = "text"
        textAttribute.attributeType = .stringAttributeType
        textAttribute.isOptional = false

        let createdAtAttribute = NSAttributeDescription()
        createdAtAttribute.name = "createdAt"
        createdAtAttribute.attributeType = .dateAttributeType
        createdAtAttribute.isOptional = false

        let userIdAttribute = NSAttributeDescription()
        userIdAttribute.name = "userId"
        userIdAttribute.attributeType = .stringAttributeType
        userIdAttribute.isOptional = true

        entity.properties = [idAttribute, userIdAttribute, textAttribute, createdAtAttribute]
        entity.uniquenessConstraints = [["userId", "id"]]

        let model = NSManagedObjectModel()
        model.entities = [entity]

        return model
    }
}
