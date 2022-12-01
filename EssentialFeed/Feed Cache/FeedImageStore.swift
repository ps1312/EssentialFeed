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

    @available(*, deprecated)
    func insert(url: URL, with data: Data, completion: @escaping InsertCompletion)
    func insert(url: URL, with data: Data) throws
}

extension FeedImageStore {
    public func insert(url: URL, with data: Data) throws {
        let group = DispatchGroup()
        group.enter()

        var capturedResult: Error?
        insert(url: url, with: data) { receivedResult in
            capturedResult = receivedResult
            group.leave()
        }

        group.wait()

        if let error = capturedResult {
            throw error
        }
    }
}
