import Foundation

public enum CacheImageRetrieveResult {
    case empty
    case found(Data)
    case failure(Error)
}

public protocol FeedImageStore {
    typealias RetrievalCompletion = (CacheImageRetrieveResult) -> Void
    typealias InsertCompletion = (Error?) -> Void

    func retrieve(from url: URL, completion: @escaping RetrievalCompletion)
    func insert(url: URL, with data: Data, completion: @escaping InsertCompletion)
}
