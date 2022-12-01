import Foundation

public protocol FeedImageLoaderTask {
    func cancel()
}

public protocol FeedImageLoader {
    typealias Result = Swift.Result<Data, Error>

    func load(from url: URL) throws -> Data
}
