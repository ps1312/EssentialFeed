import Foundation

public enum CacheImageRetrieveResult {
    case empty
    case found(Data)
    case failure(Error)
}

public protocol FeedImageStore {
    typealias RetrievalCompletion = (CacheImageRetrieveResult) -> Void
    typealias InsertCompletion = (Error?) -> Void

    func retrieve(from url: URL) throws -> CacheImageRetrieveResult
    func insert(url: URL, with data: Data) throws
}
