import CoreData

@objc(ManagedCache)
public final class ManagedCache: NSManagedObject {
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