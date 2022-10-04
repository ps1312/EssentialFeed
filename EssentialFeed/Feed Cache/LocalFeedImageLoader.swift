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

    public typealias LoadFeedImageResult = Result<Data, Error>

    public func load(from url: URL, completion: @escaping (LoadFeedImageResult) -> Void) -> FeedImageLoaderTask {
        let localTask = LocalFeedImageLoaderTask(completion)

        store.retrieve(from: url) { [weak self] result in
            guard self != nil else { return }

            switch (result) {
            case .empty:
                localTask.complete(.failure(NSError(domain: "not found", code: 404)))

            case .failure(let error):
                localTask.complete(.failure(error))

            case .found(let data):
                localTask.complete(.success(data))

            }
        }

        return localTask
    }
}

extension LocalFeedImageLoader {
    public func save(url: URL, with data: Data, completion: @escaping (Error?) -> Void) {
        store.insert(url: url, with: data) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}
