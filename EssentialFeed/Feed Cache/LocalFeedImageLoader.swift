import Foundation

public class LocalFeedImageLoader {
    private let store: FeedImageStore

    public init(store: FeedImageStore) {
        self.store = store
    }
}

extension LocalFeedImageLoader: FeedImageLoader {
    private final class LocalFeedImageLoaderTask: FeedImageLoaderTask {
        private var completion: ((LoadFeedImageResult) -> Void)?

        init(_ completion: @escaping (LoadFeedImageResult) -> Void) {
            self.completion = completion
        }

        func complete(_ result: LoadFeedImageResult) {
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

    public typealias LoadFeedImageResult = Result<Data, Error>

    public func load(from url: URL, completion: @escaping (LoadFeedImageResult) -> Void) -> FeedImageLoaderTask {
        do {
            let result = try store.retrieve(from: url)

            switch (result) {
            case .empty:
                completion(.failure(LoadError.notFound))

            case .found(let data):
                completion(.success(data))

            case .failure:
                completion(.failure(LoadError.failed))
            }

        } catch {
            completion(.failure(LoadError.failed))
        }

        return LocalFeedImageLoaderTask { _ in }
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
