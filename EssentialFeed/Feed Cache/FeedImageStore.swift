import Foundation

public protocol FeedImageStore {
    func retrieve(from url: URL) throws -> Data?
    func insert(url: URL, with data: Data) throws
}
