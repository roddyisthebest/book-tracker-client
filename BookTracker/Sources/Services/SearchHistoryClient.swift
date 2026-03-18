import ComposableArchitecture
import CoreData
import Foundation

// MARK: - Public Client Interface

struct SearchHistoryClient {
    var fetchRecent: (_ limit: Int) async throws -> [Search]
    var add: (_ text: String, _ createdAt: Date) async throws -> Void
    var delete: (_ id: String) async throws -> Void
    var clearAll: () async throws -> Void
}

// MARK: - Live Implementation (Core Data)

extension SearchHistoryClient {
    static func live(container: NSPersistentContainer = SearchHistoryCoreDataStack.shared.container) -> Self {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        func entityFetchRequest() -> NSFetchRequest<NSManagedObject> {
            let request = NSFetchRequest<NSManagedObject>(entityName: SearchHistoryCoreDataStack.entityName)
            return request
        }

        return Self(
            fetchRecent: { limit in
                try await context.perform { () -> [Search] in
                    let request = entityFetchRequest()
                    request.fetchLimit = limit
                    request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
                    let results = try context.fetch(request)
                    return results.compactMap { obj in
                        guard
                            let id = obj.value(forKey: "id") as? String,
                            let text = obj.value(forKey: "text") as? String,
                            let createdAt = obj.value(forKey: "createdAt") as? Date
                        else { return nil }
                        return Search(id: id, text: text, createdAt: createdAt)
                    }
                }
            },
            add: { text, createdAt in
                try await context.perform {
                    // Upsert by id: use the text itself as id for uniqueness
                    let id = text
                    let request = entityFetchRequest()
                    request.predicate = NSPredicate(format: "id == %@", id)
                    request.fetchLimit = 1
                    let existing = try context.fetch(request).first
                    let obj: NSManagedObject
                    if let existing {
                        obj = existing
                    } else {
                        let entity = NSEntityDescription.entity(forEntityName: SearchHistoryCoreDataStack.entityName, in: context)!
                        obj = NSManagedObject(entity: entity, insertInto: context)
                        obj.setValue(id, forKey: "id")
                    }
                    obj.setValue(text, forKey: "text")
                    obj.setValue(createdAt, forKey: "createdAt")
                    try context.save()
                    try context.obtainPermanentIDs(for: [obj])
                }
            },
            delete: { id in
                try await context.perform {
                    let request = entityFetchRequest()
                    request.predicate = NSPredicate(format: "id == %@", id)
                    request.fetchLimit = 1
                    if let obj = try context.fetch(request).first {
                        context.delete(obj)
                        try context.save()
                    }
                }
            },
            clearAll: {
                try await context.perform {
                    let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: SearchHistoryCoreDataStack.entityName)
                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetch)
                    deleteRequest.resultType = .resultTypeObjectIDs
                    let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
                    if let objectIDs = result?.result as? [NSManagedObjectID] {
                        let changes = [NSDeletedObjectsKey: objectIDs]
                        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
                    }
                }
            }
        )
    }
}
