import CoreData
import Foundation

class SearchHistoryCoreDataStack {
    static let entityName = "SearchHistory"

    private let container: NSPersistentContainer

    init() {
        let container = NSPersistentContainer(name: "SearchHistoryContainer")

        let model = NSManagedObjectModel()

        let entity = NSEntityDescription()
        entity.name = SearchHistoryCoreDataStack.entityName
        entity.managedObjectClassName = "NSManagedObject"

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .stringAttributeType
        idAttr.isOptional = false
        idAttr.isIndexed = true

        let nameAttr = NSAttributeDescription()
        nameAttr.name = "name"
        nameAttr.attributeType = .stringAttributeType
        nameAttr.isOptional = false
        nameAttr.isIndexed = true

        let createdAtAttr = NSAttributeDescription()
        createdAtAttr.name = "createdAt"
        createdAtAttr.attributeType = .dateAttributeType
        createdAtAttr.isOptional = false

        entity.properties = [idAttr, nameAttr, createdAtAttr]

        if entity.responds(to: Selector(("setUniquenessConstraints:"))) {
            entity.uniquenessConstraints = [[nameAttr]]
        }

        model.entities = [entity]

        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType

        container.persistentStoreDescriptions = [description]
        container.managedObjectModel = model

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load store: \(error)")
            }
        }

        self.container = container
    }

    func entityFetchRequest() -> NSFetchRequest<NSManagedObject> {
        NSFetchRequest<NSManagedObject>(entityName: SearchHistoryCoreDataStack.entityName)
    }

    func fetchRecent(completion: @escaping ([SearchResult]) -> Void) {
        let context = container.viewContext
        context.perform {
            let request = self.entityFetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            request.fetchLimit = 10

            do {
                let results = try context.fetch(request)
                let mapped = results.compactMap { obj -> SearchResult? in
                    guard
                        let id = obj.value(forKey: "id") as? String,
                        let text = obj.value(forKey: "name") as? String,
                        let createdAt = obj.value(forKey: "createdAt") as? Date
                    else {
                        return nil
                    }
                    return SearchResult(id: id, text: text, createdAt: createdAt)
                }
                completion(mapped)
            } catch {
                completion([])
            }
        }
    }

    func add(text: String, createdAt: Date) async throws {
        let context = container.newBackgroundContext()
        try await context.perform {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }

            // Upsert by unique 'name'
            let request = self.entityFetchRequest()
            request.predicate = NSPredicate(format: "name == %@", trimmed)
            request.fetchLimit = 1
            let existing = try context.fetch(request).first
            let obj: NSManagedObject
            if let existing {
                obj = existing
            } else {
                let entity = NSEntityDescription.entity(forEntityName: SearchHistoryCoreDataStack.entityName, in: context)!
                obj = NSManagedObject(entity: entity, insertInto: context)
                obj.setValue(UUID().uuidString, forKey: "id")
                obj.setValue(trimmed, forKey: "name")
            }
            obj.setValue(createdAt, forKey: "createdAt")
            try context.save()
        }
    }

    func delete(id: String) async throws {
        let context = container.newBackgroundContext()
        try await context.perform {
            let request = self.entityFetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            request.fetchLimit = 1
            if let obj = try context.fetch(request).first {
                context.delete(obj)
                try context.save()
            }
        }
    }
}

struct SearchResult {
    let id: String
    let text: String
    let createdAt: Date
}
