import ComposableArchitecture
import CoreData
import Foundation

// MARK: - Public Client Interface

struct SearchHistoryClient {
    var fetchRecent: (_ userId: String, _ limit: Int) async throws -> [Search]
    var add: (_ userId: String, _ text: String, _ createdAt: Date) async throws -> Void
    var delete: (_ userId: String, _ id: String) async throws -> Void
    var clearAll: (_ userId: String) async throws -> Void
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
            fetchRecent: { userId, limit in
                try await context.perform { () -> [Search] in
                    let request = entityFetchRequest()
                    request.predicate = NSPredicate(format: "userId == %@", userId)
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
            add: { userId, text, createdAt in
                try await context.perform {
                    // Upsert by id: use the text itself as id for uniqueness
                    let id = text
                    let request = entityFetchRequest()
                    request.predicate = NSPredicate(format: "userId == %@ AND id == %@", userId, id)
                    request.fetchLimit = 1
                    let existing = try context.fetch(request).first
                    let obj: NSManagedObject
                    if let existing {
                        obj = existing
                    } else {
                        let entity = NSEntityDescription.entity(forEntityName: SearchHistoryCoreDataStack.entityName, in: context)!
                        obj = NSManagedObject(entity: entity, insertInto: context)
                        obj.setValue(id, forKey: "id")
                        obj.setValue(userId, forKey: "userId")
                    }
                    obj.setValue(text, forKey: "text")
                    obj.setValue(createdAt, forKey: "createdAt")
                    try context.save()
                    try context.obtainPermanentIDs(for: [obj])
                }
            },
            delete: { userId, id in
                try await context.perform {
                    let request = entityFetchRequest()
                    request.predicate = NSPredicate(format: "userId == %@ AND id == %@", userId, id)
                    request.fetchLimit = 1
                    if let obj = try context.fetch(request).first {
                        context.delete(obj)
                        try context.save()
                    }
                }
            },
            clearAll: { userId in
                try await context.perform {
                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: SearchHistoryCoreDataStack.entityName)
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
            },
        )
    }
}
