public struct FeedViewModel: Equatable {
    public let feed: [FeedImage]

    public init(feed: [FeedImage]) {
        self.feed = feed
    }
}
