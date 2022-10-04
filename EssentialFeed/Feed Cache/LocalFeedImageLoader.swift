import Foundation

public protocol FeedImageStore {
    typealias RetrievalCompletion = (Result<Data, Error>) -> Void
    typealias InsertCompletion = (Error?) -> Void

    func retrieve(from url: URL, completion: @escaping RetrievalCompletion)
    func insert(url: URL, with data: Data, completion: @escaping InsertCompletion)
}

public class LocalFeedImageLoader {
    private let store: FeedImageStore

    public typealias LoadFeedImageResult = Result<Data, Error>

    public init(store: FeedImageStore) {
        self.store = store
    }

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

    public func load(from url: URL, completion: @escaping (LoadFeedImageResult) -> Void) -> FeedImageLoaderTask {
        let localTask = LocalFeedImageLoaderTask(completion)

        store.retrieve(from: url) { result in
            switch (result) {
            case .failure(let error):
                localTask.complete(.failure(error))

            case .success(let data):
                localTask.complete(.success(data))

            }
        }

        return localTask
    }

    public func save(url: URL, with data: Data, completion: @escaping (Error?) -> Void) {
        store.insert(url: url, with: data, completion: completion)
    }
}
