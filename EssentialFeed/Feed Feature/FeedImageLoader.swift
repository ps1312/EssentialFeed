import Foundation

public protocol FeedImageLoader {
    func load(from url: URL) throws -> Data
}
