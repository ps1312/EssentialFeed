import Foundation

public protocol FeedImageStore {
    typealias RetrievalCompletion = (Result<Data, Error>) -> Void
    typealias InsertCompletion = (Error?) -> Void

    func retrieve(from url: URL, completion: @escaping RetrievalCompletion)
    func insert(url: URL, with data: Data, completion: @escaping InsertCompletion)
}
