import Foundation

public enum CacheRetrieveResult {
    case empty
    case found(feed: [LocalFeedImage], timestamp: Date)
    case failure(Error)
}

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias PersistCompletion = (Error?) -> Void
    typealias RetrieveCompletion = (CacheRetrieveResult) -> Void

    func delete() throws
    func persist(images: [LocalFeedImage], timestamp: Date) throws
    func retrieve() throws -> CacheRetrieveResult

    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    @available(*, deprecated)
    func delete(completion: @escaping DeletionCompletion)

    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    @available(*, deprecated)
    func persist(images: [LocalFeedImage], timestamp: Date, completion: @escaping PersistCompletion)

    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    func retrieve(completion: @escaping RetrieveCompletion)
}

extension FeedStore {
    public func delete() throws {
        let group = DispatchGroup()

        group.enter()

        var capturedError: Error?
        delete { error in
            capturedError = error
            group.leave()
        }

        group.wait()

        if let error = capturedError {
            throw error
        }
    }

    public func persist(images: [LocalFeedImage], timestamp: Date) throws {
        let group = DispatchGroup()

        group.enter()

        var capturedError: Error?
        persist(images: images, timestamp: timestamp) { error in
            capturedError = error
            group.leave()
        }

        group.wait()

        if let error = capturedError {
            throw error
        }
    }

    public func retrieve() throws -> CacheRetrieveResult {
        let group = DispatchGroup()

        group.enter()

        var capturedResult: CacheRetrieveResult!
        retrieve(completion: { result in
            capturedResult = result
            group.leave()
        })

        group.wait()

        switch (capturedResult) {
        case let .failure(error):
            throw error
        case .empty, .none:
            return .empty
        case let .found(feed: feed, timestamp: timestamp):
            return .found(feed: feed, timestamp: timestamp)
        }
    }
}
