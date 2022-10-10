import Foundation
import EssentialFeed

func makeNSError() -> NSError {
    return NSError(domain: "Test", code: 1)
}

func makeURL(suffix: String = "") -> URL {
    return URL(string: "https://www.a-url\(suffix).com")!
}

func makeData() -> Data {
    return Data(UUID().uuidString.utf8)
}

func uniqueFeed() -> [FeedImage] {
    let url = URL(string: "https://www.any-url.com")!
    let feedImage1 = FeedImage(id: UUID(), description: nil, location: nil, url: url)
    let feedImage2 = FeedImage(id: UUID(), description: nil, location: nil, url: url)
    return [feedImage1, feedImage2]
}
