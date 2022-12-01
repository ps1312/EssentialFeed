import Foundation

public enum CacheImageRetrieveResult {
    case empty
    case found(Data)
    case failure(Error)
}

public protocol FeedImageStore {
    typealias RetrievalCompletion = (CacheImageRetrieveResult) -> Void
    typealias InsertCompletion = (Error?) -> Void

    @available(*, deprecated)
    func retrieve(from url: URL, completion: @escaping RetrievalCompletion)
    func retrieve(from url: URL) throws -> CacheImageRetrieveResult
    func insert(url: URL, with data: Data) throws
}

extension FeedImageStore {
    public func retrieve(from url: URL) throws -> CacheImageRetrieveResult {
        let group = DispatchGroup()
        group.enter()

        var capturedResult: CacheImageRetrieveResult!
        retrieve(from: url) { result in
            capturedResult = result
            group.leave()
        }

        group.wait()

        return capturedResult
    }
}
