public struct Paginated<Item> {
    public let feed: [Item]
    public let loadMore: ((Result<Paginated<Item>, Error>) -> Void)?

    public init(feed: [Item], loadMore: ((Result<Paginated<Item>, Error>) -> Void)?) {
        self.feed = feed
        self.loadMore = loadMore
    }
}
