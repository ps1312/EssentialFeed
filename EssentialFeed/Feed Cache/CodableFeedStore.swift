import Foundation

public final class CodableFeedStore: FeedStore {
    private struct Cache: Codable {
        private let codableFeed: [CodableFeedImage]

        let timestamp: Date
        var localFeed: [LocalFeedImage] {
            return codableFeed.map { $0.local }
        }

        init (localFeed: [LocalFeedImage], timestamp: Date) {
            self.codableFeed = localFeed.map(CodableFeedImage.init)
            self.timestamp = timestamp
        }
    }

    private struct CodableFeedImage: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL

        var local: LocalFeedImage {
            return LocalFeedImage(id: id, description: description, location: location, url: url)
        }

        init (_ local: LocalFeedImage) {
            self.id = local.id
            self.description = local.description
            self.location = local.location
            self.url = local.url
        }
    }

    private let storeURL: URL

    public init(storeURL: URL) {
        self.storeURL = storeURL
    }

    public func retrieve(completion: (CacheRetrieveResult) -> Void) {
        guard let data = try? Data(contentsOf: storeURL) else { return completion(.empty) }

        do {
            let cache = try JSONDecoder().decode(Cache.self, from: data)
            completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
        } catch {
            completion(.failure(error))
        }
    }

    public func persist(images: [LocalFeedImage], timestamp: Date, completion: PersistCompletion) {
        do {
            let encoded = try JSONEncoder().encode(Cache(localFeed: images, timestamp: timestamp))
            try encoded.write(to: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }

    public func delete(completion: DeletionCompletion) {
        guard FileManager.default.fileExists(atPath: storeURL.path) else { return completion(nil) }

        do {
            try FileManager.default.removeItem(at: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }

}
