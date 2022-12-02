import Foundation

public protocol FeedImageCache {
    func save(url: URL, with data: Data) throws
}
