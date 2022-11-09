import Foundation
import EssentialFeed

func uniqueImage(index: Int = 1) -> FeedImage {
    return FeedImage(id: UUID(), description: "description", location: "location", url: makeURL(suffix: String(describing: index)))
}

func uniqueImages() -> (models: [FeedImage], locals: [LocalFeedImage])  {
    let feedImages = [uniqueImage(index: 1), uniqueImage(index: 2)]
    let localFeedImages = feedImages.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }

    return (models: feedImages, locals: localFeedImages)
}
