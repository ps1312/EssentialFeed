public struct FeedViewModel: Equatable {
    let feed: [FeedImage]

    public init(feed: [FeedImage]) {
        self.feed = feed
    }
}
