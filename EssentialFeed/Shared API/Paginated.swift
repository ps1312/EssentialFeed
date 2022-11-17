public struct Paginated<Item> {
    public typealias LoadMoreCompletion = (Result<Paginated<Item>, Error>) -> Void

    public let feed: [Item]
    public let loadMore: ((LoadMoreCompletion) -> Void)?

    public init(feed: [Item], loadMore: ((LoadMoreCompletion) -> Void)?) {
        self.feed = feed
        self.loadMore = loadMore
    }
}
