import Foundation

extension CoreDataFeedStore: FeedImageStore {
    public func insert(url: URL, with data: Data) throws {
        try performSync { context in
            let model = try ManagedFeedImage.findBy(url: url)
            model?.data = data

            try context.save()
        }
    }

    public func retrieve(from url: URL) throws -> Data? {
        var capturedImage: Data?

        try performSync { context in
            if let imageData = context.userInfo[url] as? Data {
                capturedImage = imageData
                return
            }

            guard let imageData = try ManagedFeedImage.findBy(url: url)?.data else { return }

            capturedImage = imageData
        }

        return capturedImage
    }
}
