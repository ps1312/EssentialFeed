import CoreData

@objc(ManagedFeedImage)
public final class ManagedFeedImage: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var imageDescription: String?
    @NSManaged var location: String?
    @NSManaged var url: URL
    @NSManaged var data: Data?
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

    static func findBy(url: URL) throws -> ManagedFeedImage? {
        let request = NSFetchRequest<ManagedFeedImage>(entityName: entity().name!)
        request.predicate = NSPredicate(format: "url == %@", url.absoluteString)
        let result = try request.execute().first

        return result
    }
}
