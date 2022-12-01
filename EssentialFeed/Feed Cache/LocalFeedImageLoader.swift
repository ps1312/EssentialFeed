import Foundation

public class LocalFeedImageLoader {
    private let store: FeedImageStore

    public init(store: FeedImageStore) {
        self.store = store
    }
}

extension LocalFeedImageLoader: FeedImageLoader {
    private final class LocalFeedImageLoaderTask: FeedImageLoaderTask {
        private var completion: ((FeedImageLoader.Result) -> Void)?

        init(_ completion: @escaping (FeedImageLoader.Result) -> Void) {
            self.completion = completion
        }

        func complete(_ result: FeedImageLoader.Result) {
            completion?(result)
        }

        func cancel() {
            preventFurtherCompletions()
        }

        private func preventFurtherCompletions() {
            completion = nil
        }
    }

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

public protocol FeedImageCache {
    func save(url: URL, with data: Data, completion: @escaping (Error?) -> Void)
}

extension LocalFeedImageLoader: FeedImageCache {
    public enum SaveError: Error {
        case failed
    }

    public func save(url: URL, with data: Data, completion: @escaping (Error?) -> Void) {
        do {
            try store.insert(url: url, with: data)
            completion(nil)
        } catch {
            completion(SaveError.failed)
        }
    }
}
