import Foundation

public class CoreDataFeedStore: FeedStore {
    public init() {}

    public func delete(completion: @escaping DeletionCompletion) {
        fatalError("Not implemented yet!")
    }

    public func persist(images: [LocalFeedImage], timestamp: Date, completion: @escaping PersistCompletion) {
        fatalError("Not implemented yet!")
    }

    public func retrieve(completion: @escaping RetrieveCompletion) {
        completion(.empty)
    }

}
