import Foundation

public class LocalFeedImageLoader {
    private let store: FeedImageStore

    public init(store: FeedImageStore) {
        self.store = store
    }
}

extension LocalFeedImageLoader: FeedImageLoader {
    public enum LoadError: Error {
        case failed
        case notFound
    }

    public func load(from url: URL) throws -> Data {
        do {
            let result = try store.retrieve(from: url)

            switch (result) {
            case .empty:
                throw LoadError.notFound

            case .found(let data):
                return data

            case .failure:
                throw LoadError.failed
            }
        } catch {
            throw error
        }
    }
}

extension LocalFeedImageLoader: FeedImageCache {
    public enum SaveError: Error {
        case failed
    }

    public func save(url: URL, with data: Data) throws {
        do {
            try store.insert(url: url, with: data)
        } catch {
            throw SaveError.failed
        }
    }
}
