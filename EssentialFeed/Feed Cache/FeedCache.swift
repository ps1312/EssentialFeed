public protocol FeedCache {
    typealias SaveResult = (Error?) -> Void

    func save(feed: [FeedImage], completion: @escaping SaveResult)
}
