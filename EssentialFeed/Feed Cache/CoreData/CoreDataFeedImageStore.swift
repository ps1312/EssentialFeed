import CoreData

public class CoreDataFeedImageStore {
    private let modelName: String = "FeedStore"
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext

    public init(storeURL: URL) throws {
        container = try NSPersistentContainer.create(modelName: modelName, storeURL: storeURL)
        context = container.newBackgroundContext()
    }

    public func insert(url: URL, with data: Data, completion: @escaping FeedImageStore.InsertCompletion) {
        context.perform { [weak context] in
            do {
                try context?.save()
            } catch {
                completion(error)
            }
        }
    }
}
