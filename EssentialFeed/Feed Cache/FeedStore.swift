import Foundation

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias PersistCompletion = (Error?) -> Void

    func delete(completion: @escaping DeletionCompletion)
    func persist(items: [FeedItem], timestamp: Date, completion: @escaping PersistCompletion)
}
