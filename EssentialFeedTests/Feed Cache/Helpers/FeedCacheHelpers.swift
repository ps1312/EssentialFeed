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
