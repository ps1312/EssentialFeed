import Foundation
import EssentialFeed

final class FeedImageStoreSpy: FeedImageStore {
    enum Message: Equatable {
        case retrieve(from: URL)
        case insert(URL, Data)
    }
    var messages = [Message]()
    var insertResult: Error?
    var retrieveResult: Result<Data?, Error>?

    func retrieve(from url: URL) throws -> Data? {
        messages.append(.retrieve(from: url))

        let result = try retrieveResult?.get()
        return result
    }

    func completeRetrieve(with error: Error, at index: Int = 0) {
        retrieveResult = .failure(error)
    }

    func completeRetrieve(with data: Data, at index: Int = 0) {
        retrieveResult = .success(data)
    }

    func completeRetrieveWithEmpty(at index: Int = 0) {
        retrieveResult = .success(nil)
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
