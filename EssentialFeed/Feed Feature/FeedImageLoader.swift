import Foundation

public protocol FeedImageLoaderTask {
    func cancel()
}

public protocol FeedImageLoader {
    typealias Result = Swift.Result<Data, Error>

    @available(*, deprecated)
    func load(from url: URL, completion: @escaping (FeedImageLoader.Result) -> Void) -> FeedImageLoaderTask
    func load(from url: URL) throws -> Data
}
