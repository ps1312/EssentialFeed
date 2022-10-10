import EssentialFeed

public final class FeedLoaderSpy: FeedLoader {
    var completions = [(LoadFeedResult) -> Void]()

    public func load(completion: @escaping (LoadFeedResult) -> Void) {
        completions.append(completion)
    }

    func completeWith(feed: [FeedImage], at index: Int = 0) {
        completions[index](.success(feed))
    }

    func completeWith(error: Error, at index: Int = 0) {
        completions[index](.failure(error))
    }
}
