import Foundation
import EssentialFeed

final class FeedImageStoreSpy: FeedImageStore {
    enum Message: Equatable {
        case retrieve(from: URL)
        case insert(URL, Data)
    }
    var messages = [Message]()
    var retrievalCompletions = [RetrievalCompletion]()
    var insertCompletions = [InsertCompletion]()
    var insertResult: Error?
    var retrieveResult: CacheImageRetrieveResult = .empty

    func retrieve(from url: URL) throws -> CacheImageRetrieveResult {
        messages.append(.retrieve(from: url))
        return retrieveResult
    }

    func completeRetrieve(with error: Error, at index: Int = 0) {
        retrieveResult = .failure(error)
    }

    func completeRetrieve(with data: Data, at index: Int = 0) {
        retrieveResult = .found(data)
    }

    func completeRetrieveWithEmpty(at index: Int = 0) {
        retrieveResult = .empty
    }

    func insert(url: URL, with data: Data) throws {
        messages.append(.insert(url, data))
        if let error = insertResult {
            throw error
        }
    }

    func completeInsert(with error: Error, at index: Int = 0) {
        insertResult = error
    }

    func completeInsertWithSuccess(at index: Int = 0) {
        insertResult = nil
    }
}
