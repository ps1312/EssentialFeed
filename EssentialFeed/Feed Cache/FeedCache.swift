public protocol FeedCache {
    func save(feed: [FeedImage], completion: @escaping LocalFeedLoader.SaveResult)
}
