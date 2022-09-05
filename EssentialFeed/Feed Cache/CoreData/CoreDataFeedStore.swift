import Foundation
import CoreData

public class CoreDataFeedStore: FeedStore {

    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext

    public init(storeURL: URL) {
        let bundle = Bundle(for: CoreDataFeedStore.self)

        guard let modelURL = bundle.url(forResource: "FeedStore", withExtension: "momd") else {
            fatalError("Failed to find data model")
        }

        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to create model from file: \(modelURL)")
        }

        container = NSPersistentContainer(name: "FeedStore", managedObjectModel: mom)

        let description = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [description]

        var loadStoresErrors = [Error]()
        container.loadPersistentStores { _, error in
            if let error = error {
                loadStoresErrors.append(error)
            }
        }

        if !loadStoresErrors.isEmpty {
            fatalError("Failed to load persistent stores")
        }

        context = container.newBackgroundContext()
    }

    public func delete(completion: @escaping DeletionCompletion) {
        fatalError("Not implemented yet!")
    }

    public func persist(images: [LocalFeedImage], timestamp: Date, completion: @escaping PersistCompletion) {
        let context = self.context

        context.perform {
            do {
                let managedCache = ManagedCache(context: context)

                managedCache.timestamp = timestamp
                managedCache.feed = ManagedFeedImage.build(with: images, in: context)

                try context.save()

                completion(nil)
            } catch {}
        }

    }

    public func retrieve(completion: @escaping RetrieveCompletion) {
        let request = NSFetchRequest<ManagedCache>(entityName: ManagedCache.entity().name!)
        request.returnsObjectsAsFaults = false

        context.perform { [context] in
            do {
                if let cache = try context.fetch(request).first {
                    completion(.found(feed: cache.locals, timestamp: cache.timestamp))
                } else {
                    completion(.empty)
                }
            } catch {}
        }
    }

}

@objc(ManagedCache)
final class ManagedCache: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var feed: NSOrderedSet

    var locals: [LocalFeedImage] {
        return feed.compactMap {
            ($0 as? ManagedFeedImage).map {
                LocalFeedImage(id: $0.id, description: $0.imageDescription, location: $0.location, url: $0.url)
            }
        }
    }
}

@objc(ManagedFeedImage)
final class ManagedFeedImage: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var imageDescription: String?
    @NSManaged var location: String?
    @NSManaged var url: URL
    @NSManaged var cache: ManagedCache

    private convenience init(local: LocalFeedImage, context: NSManagedObjectContext) {
        self.init(context: context)

        id = local.id
        imageDescription = local.description
        location = local.location
        url = local.url
    }

    static func build(with images: [LocalFeedImage], in context: NSManagedObjectContext) -> NSOrderedSet {
        return NSOrderedSet(array: images.map { localFeedImage in
            return ManagedFeedImage(local: localFeedImage, context: context)
        })
    }
}
