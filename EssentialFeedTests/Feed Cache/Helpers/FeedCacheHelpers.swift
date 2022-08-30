import Foundation
import EssentialFeed

func uniqueImage() -> FeedImage {
    return FeedImage(id: UUID(), description: "description", location: "location", url: makeURL())
}

func uniqueImages() -> (models: [FeedImage], locals: [LocalFeedImage])  {
    let feedImages = [uniqueImage(), uniqueImage()]
    let localFeedImages = feedImages.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }

    return (models: feedImages, locals: localFeedImages)
}

extension Date {
    func minusFeedCacheMaxAge() -> Date {
        return adding(days: -feedCacheMaxAge)
    }

    private var feedCacheMaxAge: Int {
        return 7
    }

    private func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }

    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
