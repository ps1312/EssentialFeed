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

    public func load(from url: URL, completion: @escaping (LoadFeedImageResult) -> Void) {
        store.retrieve(from: url) { result in
            switch (result) {
            case .failure(let error):
                completion(.failure(error))

            case .success(let data):
                completion(.success(data))

            }
        }
    }

    public func save(url: URL, with data: Data, completion: @escaping (Error?) -> Void) {
        store.insert(url: url, with: data, completion: completion)
    }
}
