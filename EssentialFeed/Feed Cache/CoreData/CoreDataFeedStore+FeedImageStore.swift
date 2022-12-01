import Foundation

extension CoreDataFeedStore: FeedImageStore {
    public func insert(url: URL, with data: Data) throws {
        try performSync { context in
            let model = try ManagedFeedImage.findBy(url: url)
            model?.data = data

            try context.save()
        }
    }

    public func retrieve(from url: URL) throws -> CacheImageRetrieveResult {
        var capturedResult: CacheImageRetrieveResult!
        try performSync { context in
            if let imageData = context.userInfo[url] as? Data {
                capturedResult = .found(imageData)
                return
            }

            guard let model = try ManagedFeedImage.findBy(url: url), let imageData = model.data else {
                capturedResult = .empty
                return
            }

            capturedResult = .found(imageData)
        }

        return capturedResult
    }
}
